# OCI Database with PostgreSQL (mirrors aws/rds.tf Aurora PostgreSQL 16)
resource "oci_psql_db_system" "main" {
  compartment_id = oci_identity_compartment.main.id
  display_name   = local.name_prefix

  db_version = var.db_version
  shape      = var.db_shape

  # Flex shapes size via top-level args (the psql service has no shape_config
  # block — unlike container instances)
  instance_ocpu_count         = var.db_ocpus
  instance_memory_size_in_gbs = var.db_memory_in_gbs
  instance_count              = var.db_instance_count

  credentials {
    username = var.db_user

    # Password injected via Infisical as TF_VAR_DATABASE_PASSWORD
    password_details {
      password_type = "PLAIN_TEXT"
      password      = var.DATABASE_PASSWORD
    }
  }

  network_details {
    subnet_id = oci_core_subnet.private.id
    nsg_ids   = [oci_core_network_security_group.db.id]

    # Read scaling guide: enable alongside instance_count > 1 (see below)
    is_reader_endpoint_enabled = var.db_instance_count > 1
  }

  storage_details {
    system_type           = "OCI_OPTIMIZED_STORAGE"
    is_regionally_durable = true
  }

  management_policy {
    backup_policy {
      kind           = "DAILY"
      backup_start   = "03:00"
      retention_days = var.db_backup_retention_days
    }
  }

  freeform_tags = local.common_tags
}

# Read scaling guide: with db_instance_count > 1 the extra nodes are HA
# standbys AND readers, but the apps only use the primary endpoint.
# To offload reads at high traffic:
#   1. raise db_instance_count (the service fans reads across replica nodes)
#   2. keep network_details.is_reader_endpoint_enabled = true (done above)
#      and expose the reader endpoint as DATABASE_READ_HOST in
#      container_instances.tf local.backend_environment
#   3. route read-only queries to it in the application layer
# The service has a built-in connection pooler (pgBouncer-style) you can
# enable per DB system from the console/API when connection counts grow.

# The default database is named after the admin user; create the app database
# explicitly so DATABASE_NAME matches the other stacks.
# NOTE: oci_psql_db_system has no "database name" argument — run once after
# provisioning (or let migrations handle it):
#   CREATE DATABASE app OWNER app;
