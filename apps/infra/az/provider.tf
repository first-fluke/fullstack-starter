# azurerm 4.x+ requires an explicit subscription: set ARM_SUBSCRIPTION_ID
# (and ARM_TENANT_ID for OIDC) in the environment, or subscription_id here.
# azurerm has no default_tags equivalent — common tags live in
# locals.common_tags and are applied to every taggable resource.
provider "azurerm" {
  # azurerm 5.x no longer auto-registers Resource Providers ("legacy" set in
  # 4.x). This stack registers them out of band — see the README
  # prerequisites list — so Terraform needs no subscription-wide register
  # permission. Pinned explicitly to make the choice visible.
  resource_provider_registrations = "none"

  features {}
}

provider "azuread" {}
