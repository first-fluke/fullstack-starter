# Cloud SQL PostgreSQL Instance
resource "google_sql_database_instance" "main" {
  name             = "${local.name_prefix}-postgres"
  database_version = "POSTGRES_16"
  region           = var.region

  depends_on = [google_service_networking_connection.private_vpc_connection]

  settings {
    tier              = var.db_tier
    availability_type = var.environment == "prod" ? "REGIONAL" : "ZONAL"
    disk_size         = 10
    disk_type         = "PD_SSD"
    disk_autoresize   = true

    ip_configuration {
      ipv4_enabled                                  = false
      private_network                               = google_compute_network.main.id
      enable_private_path_for_google_cloud_services = true
    }

    backup_configuration {
      enabled                        = true
      start_time                     = "03:00"
      point_in_time_recovery_enabled = var.environment == "prod"
      backup_retention_settings {
        retained_backups = var.environment == "prod" ? 30 : 7
      }
    }

    maintenance_window {
      day          = 7 # Sunday
      hour         = 4
      update_track = "stable"
    }

    database_flags {
      name  = "log_checkpoints"
      value = "on"
    }

    database_flags {
      name  = "log_connections"
      value = "on"
    }

    database_flags {
      name  = "log_disconnections"
      value = "on"
    }

    user_labels = local.labels
  }

  deletion_protection = var.environment == "prod"
}

# Read scaling guide: REGIONAL availability_type above is failover-only.
# To offload reads at high traffic, add a replica and wire it to the apps:
#
#   resource "google_sql_database_instance" "read_replica" {
#     name                 = "${local.name_prefix}-postgres-replica"
#     master_instance_name = google_sql_database_instance.main.name
#     database_version     = "POSTGRES_16"
#     region               = var.region
#     settings { tier = var.db_tier }
#   }
#
# then expose it as DATABASE_READ_HOST env in compute.tf
# (google_sql_database_instance.read_replica.private_ip_address) and route
# read-only queries to it in the application layer.

# Database
resource "google_sql_database" "main" {
  name     = var.db_name
  instance = google_sql_database_instance.main.name
}

# Database User (password injected via Infisical as TF_VAR_DATABASE_PASSWORD)
resource "google_sql_user" "main" {
  name     = var.db_user
  instance = google_sql_database_instance.main.name
  password = var.DATABASE_PASSWORD
}

# Redis (Memorystore)
resource "google_redis_instance" "main" {
  name           = "${local.name_prefix}-redis"
  tier           = var.environment == "prod" ? "STANDARD_HA" : "BASIC"
  memory_size_gb = var.redis_memory_size_gb
  region         = var.region

  authorized_network = google_compute_network.main.id
  connect_mode       = "PRIVATE_SERVICE_ACCESS"

  redis_version = "REDIS_7_2"

  maintenance_policy {
    weekly_maintenance_window {
      day = "SUNDAY"
      start_time {
        hours   = 4
        minutes = 0
      }
    }
  }

  labels = local.labels

  depends_on = [google_service_networking_connection.private_vpc_connection]
}
