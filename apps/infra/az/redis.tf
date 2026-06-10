# Azure Cache for Redis (Basic dev / Standard prod), TLS only.
# Basic/Standard tiers don't support VNet injection (Premium only) — access is
# over the public endpoint with TLS + access key auth; add a Private Endpoint
# for private-only access if required.
resource "azurerm_redis_cache" "main" {
  name                = "${local.name_prefix}-${local.unique_suffix}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location

  capacity = var.redis_capacity
  family   = var.redis_family
  sku_name = var.redis_sku_name

  redis_version        = "6"
  non_ssl_port_enabled = false
  minimum_tls_version  = "1.2"

  tags = local.common_tags
}
