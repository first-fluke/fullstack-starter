# azurerm 4.x requires an explicit subscription: set ARM_SUBSCRIPTION_ID
# (and ARM_TENANT_ID for OIDC) in the environment, or subscription_id here.
# azurerm has no default_tags equivalent — common tags live in
# locals.common_tags and are applied to every taggable resource.
provider "azurerm" {
  features {}
}

provider "azuread" {}
