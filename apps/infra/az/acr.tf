# Azure Container Registry (mirrors aws/ecr.tf — one registry, api/web/worker
# repositories are created implicitly on first push).
# Note: native retention policies (ECR "keep last 10") require the Premium SKU
# on ACR, so retention runs as a scheduled `acr purge` task instead (below) —
# ACR Tasks are available on every SKU tier.
resource "azurerm_container_registry" "main" {
  name                = substr("${local.alnum_prefix}${local.unique_suffix}", 0, 50)
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  sku                 = var.acr_sku
  admin_enabled       = false

  tags = local.common_tags
}

# Scheduled image retention (stands in for the Premium-only retention policy and
# mirrors aws_ecr_lifecycle_policy). CI tags images with the full commit SHA
# (`github.sha`), so the filters match hex tags only — `:latest`, which
# locals.tf pins the container apps to, is never a purge candidate.
resource "azurerm_container_registry_task" "purge" {
  name                  = "daily-purge"
  container_registry_id = azurerm_container_registry.main.id
  tags                  = local.common_tags

  platform {
    os = "Linux"
  }

  encoded_step {
    task_content = base64encode(<<-YAML
      version: v1.1.0
      steps:
        - cmd: acr purge --filter 'api:^[0-9a-f]{7,40}$' --filter 'web:^[0-9a-f]{7,40}$' --filter 'worker:^[0-9a-f]{7,40}$' --ago 0d --keep 2 --untagged
          disableWorkingDirectoryOverride: true
          timeout: 3600
    YAML
    )
  }

  timer_trigger {
    name     = "daily"
    schedule = "0 19 * * *" # 04:00 KST
    enabled  = true
  }
}

# User-assigned identity shared by the container apps and jobs
# (image pulls + data-plane access, mirrors aws_iam_role.ecs_task)
resource "azurerm_user_assigned_identity" "apps" {
  name                = "${local.name_prefix}-apps"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location

  tags = local.common_tags
}

resource "azurerm_role_assignment" "apps_acr_pull" {
  scope                = azurerm_container_registry.main.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_user_assigned_identity.apps.principal_id
}

resource "azurerm_role_assignment" "apps_storage" {
  scope                = azurerm_storage_account.main.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_user_assigned_identity.apps.principal_id
}

resource "azurerm_role_assignment" "apps_servicebus" {
  scope                = azurerm_servicebus_namespace.main.id
  role_definition_name = "Azure Service Bus Data Owner"
  principal_id         = azurerm_user_assigned_identity.apps.principal_id
}
