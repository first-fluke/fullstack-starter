# Container Apps environment + api/web/worker apps
# (mirrors aws/ecs.tf ECS cluster/services and gcp/compute.tf Cloud Run)

resource "azurerm_log_analytics_workspace" "main" {
  name                = "${local.name_prefix}-logs"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  sku                 = "PerGB2018"
  retention_in_days   = 30

  tags = local.common_tags
}

resource "azurerm_container_app_environment" "main" {
  name                       = "${local.name_prefix}-env"
  resource_group_name        = azurerm_resource_group.main.name
  location                   = azurerm_resource_group.main.location
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id

  # VNet integration so apps reach the private PostgreSQL server
  infrastructure_subnet_id = azurerm_subnet.containerapps.id

  workload_profile {
    name                  = "Consumption"
    workload_profile_type = "Consumption"
  }

  tags = local.common_tags
}

locals {
  # Shared backend environment (api + worker + jobs),
  # mirrors aws/ecs.tf local.backend_environment
  backend_environment = [
    { name = "ENVIRONMENT", value = var.environment, secret_name = null },
    { name = "AZURE_LOCATION", value = var.location, secret_name = null },
    { name = "DATABASE_HOST", value = azurerm_postgresql_flexible_server.main.fqdn, secret_name = null },
    # Read scaling guide: add when a read replica is enabled (see postgres.tf)
    # { name = "DATABASE_READ_HOST", value = azurerm_postgresql_flexible_server.replica.fqdn, secret_name = null },
    { name = "DATABASE_NAME", value = var.db_name, secret_name = null },
    { name = "DATABASE_USER", value = var.db_user, secret_name = null },
    { name = "DATABASE_PASSWORD", value = null, secret_name = "database-password" },
    { name = "REDIS_HOST", value = azurerm_redis_cache.main.hostname, secret_name = null },
    { name = "REDIS_PORT", value = tostring(azurerm_redis_cache.main.ssl_port), secret_name = null },
    { name = "REDIS_TLS", value = "true", secret_name = null },
    { name = "REDIS_PASSWORD", value = null, secret_name = "redis-password" },
    { name = "STORAGE_ACCOUNT", value = azurerm_storage_account.main.name, secret_name = null },
    { name = "STORAGE_BUCKET", value = azurerm_storage_container.uploads.name, secret_name = null },
    { name = "SERVICEBUS_NAMESPACE", value = azurerm_servicebus_namespace.main.name, secret_name = null },
    { name = "SERVICEBUS_TOPIC", value = azurerm_servicebus_topic.tasks.name, secret_name = null },
  ]

  # Container Apps secrets shared by api + worker + jobs
  backend_secrets = {
    "database-password"     = var.DATABASE_PASSWORD
    "redis-password"        = azurerm_redis_cache.main.primary_access_key
    "servicebus-connection" = azurerm_servicebus_namespace_authorization_rule.worker.primary_connection_string
  }

  worker_environment = concat(local.backend_environment, [
    { name = "OPENAI_API_KEY", value = var.OPENAI_API_KEY, secret_name = null },
    { name = "ANTHROPIC_API_KEY", value = var.ANTHROPIC_API_KEY, secret_name = null },
    { name = "GOOGLE_AI_API_KEY", value = var.GOOGLE_AI_API_KEY, secret_name = null },
  ])
}

# API
resource "azurerm_container_app" "api" {
  name                         = "${local.name_prefix}-api"
  container_app_environment_id = azurerm_container_app_environment.main.id
  resource_group_name          = azurerm_resource_group.main.name
  revision_mode                = "Single"
  workload_profile_name        = "Consumption"

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.apps.id]
  }

  registry {
    server   = azurerm_container_registry.main.login_server
    identity = azurerm_user_assigned_identity.apps.id
  }

  dynamic "secret" {
    for_each = merge(local.backend_secrets, { "jwt-secret" = var.JWT_SECRET })
    content {
      name  = secret.key
      value = secret.value
    }
  }

  ingress {
    external_enabled = true
    target_port      = 8000
    transport        = "auto"

    traffic_weight {
      latest_revision = true
      percentage      = 100
    }
  }

  template {
    min_replicas = var.api_min_replicas
    max_replicas = var.api_max_replicas

    http_scale_rule {
      name                = "http-concurrency"
      concurrent_requests = tostring(var.api_concurrent_requests)
    }

    container {
      name   = "api"
      image  = local.api_image
      cpu    = var.api_cpu
      memory = var.api_memory

      dynamic "env" {
        for_each = concat(local.backend_environment, [
          { name = "JWT_SECRET", value = null, secret_name = "jwt-secret" },
          { name = "API_URL", value = local.api_url, secret_name = null },
        ])
        content {
          name        = env.value.name
          value       = env.value.value
          secret_name = env.value.secret_name
        }
      }

      liveness_probe {
        transport = "HTTP"
        port      = 8000
        path      = "/health"
      }

      startup_probe {
        transport = "HTTP"
        port      = 8000
        path      = "/health"
      }
    }
  }

  lifecycle {
    # CI/CD deploys new image tags via `az containerapp update` — don't revert
    ignore_changes = [template[0].container[0].image]
  }

  tags = local.common_tags
}

# Web
resource "azurerm_container_app" "web" {
  name                         = "${local.name_prefix}-web"
  container_app_environment_id = azurerm_container_app_environment.main.id
  resource_group_name          = azurerm_resource_group.main.name
  revision_mode                = "Single"
  workload_profile_name        = "Consumption"

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.apps.id]
  }

  registry {
    server   = azurerm_container_registry.main.login_server
    identity = azurerm_user_assigned_identity.apps.id
  }

  secret {
    name  = "better-auth-secret"
    value = var.BETTER_AUTH_SECRET
  }

  ingress {
    external_enabled = true
    target_port      = 3000
    transport        = "auto"

    traffic_weight {
      latest_revision = true
      percentage      = 100
    }
  }

  template {
    min_replicas = var.web_min_replicas
    max_replicas = var.web_max_replicas

    http_scale_rule {
      name                = "http-concurrency"
      concurrent_requests = tostring(var.api_concurrent_requests)
    }

    container {
      name   = "web"
      image  = local.web_image
      cpu    = var.web_cpu
      memory = var.web_memory

      dynamic "env" {
        for_each = [
          { name = "ENVIRONMENT", value = var.environment, secret_name = null },
          { name = "NEXT_PUBLIC_API_URL", value = local.api_url, secret_name = null },
          { name = "BETTER_AUTH_SECRET", value = null, secret_name = "better-auth-secret" },
          { name = "BETTER_AUTH_URL", value = local.web_url, secret_name = null },
          { name = "GOOGLE_CLIENT_ID", value = var.GOOGLE_CLIENT_ID, secret_name = null },
          { name = "GOOGLE_CLIENT_SECRET", value = var.GOOGLE_CLIENT_SECRET, secret_name = null },
          { name = "GITHUB_CLIENT_ID", value = var.GITHUB_CLIENT_ID, secret_name = null },
          { name = "GITHUB_CLIENT_SECRET", value = var.GITHUB_CLIENT_SECRET, secret_name = null },
          { name = "KAKAO_CLIENT_ID", value = var.KAKAO_CLIENT_ID, secret_name = null },
          { name = "KAKAO_CLIENT_SECRET", value = var.KAKAO_CLIENT_SECRET, secret_name = null },
        ]
        content {
          name        = env.value.name
          value       = env.value.value
          secret_name = env.value.secret_name
        }
      }
    }
  }

  lifecycle {
    ignore_changes = [template[0].container[0].image]
  }

  tags = local.common_tags
}

# Worker — no ingress (internal only), scales on Service Bus subscription depth
resource "azurerm_container_app" "worker" {
  name                         = "${local.name_prefix}-worker"
  container_app_environment_id = azurerm_container_app_environment.main.id
  resource_group_name          = azurerm_resource_group.main.name
  revision_mode                = "Single"
  workload_profile_name        = "Consumption"

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.apps.id]
  }

  registry {
    server   = azurerm_container_registry.main.login_server
    identity = azurerm_user_assigned_identity.apps.id
  }

  dynamic "secret" {
    for_each = local.backend_secrets
    content {
      name  = secret.key
      value = secret.value
    }
  }

  template {
    min_replicas = var.worker_min_replicas
    max_replicas = var.worker_max_replicas

    # KEDA azure-servicebus scaler on the default subscription
    # (mirrors aws/autoscaling.tf worker queue-depth target tracking)
    custom_scale_rule {
      name             = "servicebus-queue-depth"
      custom_rule_type = "azure-servicebus"

      metadata = {
        topicName        = azurerm_servicebus_topic.tasks.name
        subscriptionName = "default"
        messageCount     = tostring(var.worker_queue_depth_target)
      }

      authentication {
        secret_name       = "servicebus-connection"
        trigger_parameter = "connection"
      }
    }

    container {
      name   = "worker"
      image  = local.worker_image
      cpu    = var.worker_cpu
      memory = var.worker_memory

      dynamic "env" {
        for_each = local.worker_environment
        content {
          name        = env.value.name
          value       = env.value.value
          secret_name = env.value.secret_name
        }
      }
    }
  }

  lifecycle {
    ignore_changes = [template[0].container[0].image]
  }

  tags = local.common_tags
}
