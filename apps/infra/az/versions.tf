terraform {
  required_version = ">= 1.9.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.79"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 3.0"
    }
  }

  backend "azurerm" {
    # Configure via backend config file or CLI:
    # terraform init \
    #   -backend-config="resource_group_name=your-tfstate-rg" \
    #   -backend-config="storage_account_name=yourtfstateaccount" \
    #   -backend-config="container_name=tfstate" \
    #   -backend-config="key=az/terraform.tfstate"
  }
}
