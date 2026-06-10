# Container Apps Jobs (cron) -> worker image with TASK_PAYLOAD
# Scheduled jobs belong here, not in in-worker cron loops: with N worker
# replicas an in-process cron fires N times, while a cron-triggered job
# runs exactly once per tick.
#
# Job names are capped at 32 characters (app_name-environment-key).
#
# Example tfvars:
#   schedules = {
#     report = {
#       schedule_expression = "0 3 * * *"
#       payload             = "{\"task\":\"daily_report\"}"
#     }
#   }

resource "azurerm_container_app_job" "scheduled" {
  for_each = var.schedules

  name                         = "${local.name_prefix}-${each.key}"
  resource_group_name          = azurerm_resource_group.main.name
  location                     = azurerm_resource_group.main.location
  container_app_environment_id = azurerm_container_app_environment.main.id
  workload_profile_name        = "Consumption"

  replica_timeout_in_seconds = 300
  replica_retry_limit        = 1

  schedule_trigger_config {
    cron_expression          = each.value.schedule_expression
    parallelism              = 1
    replica_completion_count = 1
  }

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
    container {
      name   = "worker"
      image  = local.worker_image
      cpu    = var.worker_cpu
      memory = var.worker_memory

      dynamic "env" {
        for_each = concat(local.worker_environment, [
          { name = "TASK_PAYLOAD", value = each.value.payload, secret_name = null },
        ])
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
