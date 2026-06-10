# Static assets container served via Azure Front Door
# (mirrors aws/cdn.tf S3 + CloudFront OAC).
#
# Private-origin note: Front Door Standard cannot reach a private blob
# container — Private Link origins require the Premium SKU (the Azure
# equivalent of CloudFront OAC). With Standard, either:
#   - flip container_access_type to "blob" (anonymous read on blobs, listing
#     still blocked) and set allow_nested_items_to_be_public = true on the
#     account, or
#   - upgrade the profile to Premium_AzureFrontDoor and add a private_link
#     block to the origin.
resource "azurerm_storage_container" "static" {
  name                  = "static"
  storage_account_id    = azurerm_storage_account.main.id
  container_access_type = "private"
}

resource "azurerm_cdn_frontdoor_profile" "main" {
  name                = "${local.name_prefix}-fd"
  resource_group_name = azurerm_resource_group.main.name
  sku_name            = "Standard_AzureFrontDoor"

  tags = local.common_tags
}

resource "azurerm_cdn_frontdoor_endpoint" "static" {
  name                     = "${local.name_prefix}-${local.unique_suffix}"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.main.id

  tags = local.common_tags
}

resource "azurerm_cdn_frontdoor_origin_group" "static" {
  name                     = "static"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.main.id

  load_balancing {
    sample_size                 = 4
    successful_samples_required = 3
  }

  health_probe {
    protocol            = "Https"
    interval_in_seconds = 100
    request_type        = "HEAD"
    path                = "/"
  }
}

resource "azurerm_cdn_frontdoor_origin" "static_blob" {
  name                          = "static-blob"
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.static.id

  enabled                        = true
  host_name                      = azurerm_storage_account.main.primary_blob_host
  origin_host_header             = azurerm_storage_account.main.primary_blob_host
  certificate_name_check_enabled = true
  priority                       = 1
  weight                         = 1000
}

resource "azurerm_cdn_frontdoor_route" "static" {
  name                          = "static"
  cdn_frontdoor_endpoint_id     = azurerm_cdn_frontdoor_endpoint.static.id
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.static.id
  cdn_frontdoor_origin_ids      = [azurerm_cdn_frontdoor_origin.static_blob.id]

  supported_protocols    = ["Http", "Https"]
  patterns_to_match      = ["/*"]
  forwarding_protocol    = "HttpsOnly"
  https_redirect_enabled = true
  link_to_default_domain = true

  cache {
    query_string_caching_behavior = "IgnoreQueryString"
    compression_enabled           = true
    content_types_to_compress = [
      "application/javascript",
      "application/json",
      "image/svg+xml",
      "text/css",
      "text/html",
      "text/plain",
    ]
  }
}
