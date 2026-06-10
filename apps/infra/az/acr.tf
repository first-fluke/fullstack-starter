# Azure Container Registry (mirrors aws/ecr.tf — one registry, api/web/worker
# repositories are created implicitly on first push).
# Note: image retention/cleanup policies (ECR "keep last 10") require the
# Premium SKU on ACR; use `az acr run --cmd "acr purge ..."` in CI if needed.
resource "azurerm_container_registry" "main" {
  name                = substr("${local.alnum_prefix}${local.unique_suffix}", 0, 50)
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  sku                 = var.acr_sku
  admin_enabled       = false

  tags = local.common_tags
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
