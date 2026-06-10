# GitHub Actions OIDC via Entra ID
# (mirrors aws/iam.tf OIDC provider+role and gcp/wif.tf Workload Identity)
resource "azuread_application" "github" {
  display_name = "${local.name_prefix}-github-actions"
}

resource "azuread_service_principal" "github" {
  client_id = azuread_application.github.client_id
}

# Trust GitHub Actions tokens for pushes to main
# (azure/login consumes client-id / tenant-id / subscription-id, see outputs)
resource "azuread_application_federated_identity_credential" "github_main" {
  application_id = azuread_application.github.id
  display_name   = "github-main"
  description    = "GitHub Actions deployments from ${var.github_repository} main"
  audiences      = ["api://AzureADTokenExchange"]
  issuer         = "https://token.actions.githubusercontent.com"
  subject        = "repo:${var.github_repository}:ref:refs/heads/main"
}

# Push images to ACR
resource "azurerm_role_assignment" "github_acr_push" {
  scope                = azurerm_container_registry.main.id
  role_definition_name = "AcrPush"
  principal_id         = azuread_service_principal.github.object_id
}

# Deploy container apps / jobs (scoped to the stack's resource group only)
resource "azurerm_role_assignment" "github_contributor" {
  scope                = azurerm_resource_group.main.id
  role_definition_name = "Contributor"
  principal_id         = azuread_service_principal.github.object_id
}
