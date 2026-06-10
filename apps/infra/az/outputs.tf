output "resource_group_name" {
  description = "Resource group name"
  value       = azurerm_resource_group.main.name
}

output "api_url" {
  description = "API base URL"
  value       = local.api_url
}

output "web_url" {
  description = "Web base URL"
  value       = local.web_url
}

output "acr_login_server" {
  description = "ACR login server (push api/web/worker images here)"
  value       = azurerm_container_registry.main.login_server
}

# azure/login OIDC inputs for GitHub Actions
output "github_actions_client_id" {
  description = "Entra ID application client ID for azure/login (client-id)"
  value       = azuread_application.github.client_id
}

output "tenant_id" {
  description = "Entra ID tenant ID for azure/login (tenant-id)"
  value       = data.azurerm_client_config.current.tenant_id
}

output "subscription_id" {
  description = "Azure subscription ID for azure/login (subscription-id)"
  value       = data.azurerm_client_config.current.subscription_id
}

output "db_fqdn" {
  description = "PostgreSQL Flexible Server FQDN"
  value       = azurerm_postgresql_flexible_server.main.fqdn
  sensitive   = true
}

output "redis_hostname" {
  description = "Azure Cache for Redis hostname"
  value       = azurerm_redis_cache.main.hostname
  sensitive   = true
}

output "front_door_endpoint" {
  description = "Front Door endpoint hostname for static assets"
  value       = azurerm_cdn_frontdoor_endpoint.static.host_name
}

output "servicebus_namespace" {
  description = "Service Bus namespace name"
  value       = azurerm_servicebus_namespace.main.name
}

output "uploads_container" {
  description = "Uploads blob container name"
  value       = azurerm_storage_container.uploads.name
}
