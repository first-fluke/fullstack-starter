# Azure Monitor (mirrors aws/monitoring.tf CloudWatch alarms)
# The Log Analytics workspace wired to the Container Apps environment lives
# in containerapps.tf — it is required regardless of enable_monitoring.

# Warn if monitoring is enabled in prod but no alarm_email is set
check "prod_alarm_email" {
  assert {
    condition     = !(var.environment == "prod" && var.enable_monitoring && var.alarm_email == "")
    error_message = "WARNING: alarm_email is empty in prod — alerts have no subscriber."
  }
}

resource "azurerm_monitor_action_group" "alarms" {
  count = var.enable_monitoring ? 1 : 0

  name                = "${local.name_prefix}-alarms"
  resource_group_name = azurerm_resource_group.main.name
  short_name          = "alarms"

  dynamic "email_receiver" {
    for_each = var.alarm_email != "" ? [var.alarm_email] : []
    content {
      name          = "ops"
      email_address = email_receiver.value
    }
  }

  tags = local.common_tags
}

# API CPU high — UsageNanoCores is absolute, so the threshold is 80% of the
# per-replica allocation (var.api_cpu cores * 1e9 nanocores)
resource "azurerm_monitor_metric_alert" "api_high_cpu" {
  count = var.enable_monitoring ? 1 : 0

  name                = "${local.name_prefix}-api-high-cpu"
  resource_group_name = azurerm_resource_group.main.name
  scopes              = [azurerm_container_app.api.id]
  description         = "API container app CPU usage exceeds 80% of its allocation"
  severity            = 2
  frequency           = "PT1M"
  window_size         = "PT5M"

  criteria {
    metric_namespace = "Microsoft.App/containerApps"
    metric_name      = "UsageNanoCores"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = var.api_cpu * 0.8 * 1000000000
  }

  action {
    action_group_id = one(azurerm_monitor_action_group.alarms[*].id)
  }

  tags = local.common_tags
}

resource "azurerm_monitor_metric_alert" "postgres_high_cpu" {
  count = var.enable_monitoring ? 1 : 0

  name                = "${local.name_prefix}-postgres-high-cpu"
  resource_group_name = azurerm_resource_group.main.name
  scopes              = [azurerm_postgresql_flexible_server.main.id]
  description         = "PostgreSQL Flexible Server CPU utilization exceeds 80%"
  severity            = 2
  frequency           = "PT1M"
  window_size         = "PT5M"

  criteria {
    metric_namespace = "Microsoft.DBforPostgreSQL/flexibleServers"
    metric_name      = "cpu_percent"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 80
  }

  action {
    action_group_id = one(azurerm_monitor_action_group.alarms[*].id)
  }

  tags = local.common_tags
}
