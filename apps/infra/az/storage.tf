# Storage account + blob containers (mirrors aws/storage.tf S3 buckets)
resource "azurerm_storage_account" "main" {
  name                = substr("${local.alnum_prefix}${local.unique_suffix}", 0, 24)
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location

  account_tier             = "Standard"
  account_replication_type = "LRS"

  min_tls_version                 = "TLS1_2"
  allow_nested_items_to_be_public = false

  blob_properties {
    # Blob versioning is account-wide (mirrors prod-only S3 versioning)
    versioning_enabled = var.environment == "prod"

    cors_rule {
      allowed_origins    = ["*"]
      allowed_methods    = ["GET", "PUT", "POST", "DELETE"]
      allowed_headers    = ["*"]
      exposed_headers    = ["*"]
      max_age_in_seconds = 3600
    }
  }

  tags = local.common_tags
}

resource "azurerm_storage_container" "uploads" {
  name                  = "uploads"
  storage_account_id    = azurerm_storage_account.main.id
  container_access_type = "private"
}

# Expire old uploads after 90 days (mirrors the S3 lifecycle rule)
resource "azurerm_storage_management_policy" "main" {
  storage_account_id = azurerm_storage_account.main.id

  rule {
    name    = "expire-old-uploads"
    enabled = true

    filters {
      prefix_match = ["uploads/"]
      blob_types   = ["blockBlob"]
    }

    actions {
      base_blob {
        delete_after_days_since_modification_greater_than = 90
      }
    }
  }
}
