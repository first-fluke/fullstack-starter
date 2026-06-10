locals {
  name_prefix = "${var.app_name}-${var.environment}"

  # azurerm has no provider-level default_tags — apply these to every
  # taggable resource (mirrors gcp/locals.tf labels and the AWS default_tags)
  common_tags = {
    app         = var.app_name
    environment = var.environment
    managed_by  = "terraform"
  }

  # Subscription-scoped suffix for globally unique names
  # (mirrors the AWS account-id suffix in aws/storage.tf)
  unique_suffix = substr(replace(data.azurerm_client_config.current.subscription_id, "-", ""), 0, 8)

  # Alphanumeric-only prefix for resources that reject hyphens
  # (storage account, ACR, Front Door WAF policy)
  alnum_prefix = replace(local.name_prefix, "-", "")

  # Service Bus subscriptions mirror the AWS SNS -> SQS fan-out tiers (aws/sns.tf)
  subscription_names = ["default", "high-priority", "low-priority"]

  # SQL filters on the "priority" application property (aws/sns.tf filter_policy)
  subscription_sql_filters = {
    "default"       = "priority IS NULL OR priority = 'default'"
    "high-priority" = "priority = 'high'"
    "low-priority"  = "priority = 'low'"
  }

  api_image    = "${azurerm_container_registry.main.login_server}/api:latest"
  web_image    = "${azurerm_container_registry.main.login_server}/web:latest"
  worker_image = "${azurerm_container_registry.main.login_server}/worker:latest"

  api_url = var.domain != "" ? "https://${var.api_subdomain}.${var.domain}" : "https://${local.name_prefix}-api.${azurerm_container_app_environment.main.default_domain}"
  web_url = var.domain != "" ? "https://${var.domain}" : "https://${local.name_prefix}-web.${azurerm_container_app_environment.main.default_domain}"
}
