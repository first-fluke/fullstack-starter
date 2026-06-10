# Azure Database for PostgreSQL Flexible Server 16
# Private access only: delegated subnet + private DNS zone, no public endpoint.
resource "azurerm_postgresql_flexible_server" "main" {
  name                = "${local.name_prefix}-${local.unique_suffix}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location

  version  = "16"
  sku_name = var.db_sku_name

  administrator_login = var.db_user
  # Password injected via Infisical as TF_VAR_DATABASE_PASSWORD
  administrator_password = var.DATABASE_PASSWORD

  delegated_subnet_id           = azurerm_subnet.postgres.id
  private_dns_zone_id           = azurerm_private_dns_zone.postgres.id
  public_network_access_enabled = false

  storage_mb                   = var.db_storage_mb
  zone                         = "1"
  backup_retention_days        = var.db_backup_retention_days
  geo_redundant_backup_enabled = var.db_geo_redundant_backup

  dynamic "high_availability" {
    for_each = var.db_high_availability ? [1] : []
    content {
      mode                      = "ZoneRedundant"
      standby_availability_zone = "2"
    }
  }

  lifecycle {
    # A zone failover swaps primary/standby zones — don't fight it from state
    ignore_changes = [zone, high_availability[0].standby_availability_zone]
  }

  depends_on = [azurerm_private_dns_zone_virtual_network_link.postgres]

  tags = local.common_tags
}

resource "azurerm_postgresql_flexible_server_database" "main" {
  name      = var.db_name
  server_id = azurerm_postgresql_flexible_server.main.id
  collation = "en_US.utf8"
  charset   = "utf8"
}

# Mirrors the aws/rds.tf cluster parameter group
resource "azurerm_postgresql_flexible_server_configuration" "shared_preload_libraries" {
  name      = "shared_preload_libraries"
  server_id = azurerm_postgresql_flexible_server.main.id
  value     = "pg_stat_statements"
}

# Read scaling guide: Flexible Server supports read replicas via
# create_mode = "Replica" (up to 5 per primary, General Purpose+ SKUs).
# To offload reads at high traffic:
#   1. add a replica server:
#        resource "azurerm_postgresql_flexible_server" "replica" {
#          name             = "${local.name_prefix}-replica-${local.unique_suffix}"
#          create_mode      = "Replica"
#          source_server_id = azurerm_postgresql_flexible_server.main.id
#          ...
#        }
#   2. expose azurerm_postgresql_flexible_server.replica.fqdn as
#      DATABASE_READ_HOST in containerapps.tf local.backend_environment
#   3. route read-only queries to it in the application layer
# For connection pooling at scale, enable the built-in PgBouncer
# (azurerm_postgresql_flexible_server_configuration "pgbouncer.enabled").
