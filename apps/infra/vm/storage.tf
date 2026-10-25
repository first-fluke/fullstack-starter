# Encrypted-at-rest database backups uploaded by the VM's daily cron
resource "google_storage_bucket" "backups" {
  name     = "${var.project_id}-${local.name_prefix}-backups"
  location = var.region

  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"
  force_destroy               = false

  versioning {
    enabled = true
  }

  lifecycle_rule {
    condition {
      age = var.backup_retention_days
    }
    action {
      type = "Delete"
    }
  }

  lifecycle {
    prevent_destroy = true
  }

  labels = local.labels

  depends_on = [google_project_service.apis]
}

# Application uploads (API STORAGE_BACKEND=gcs, GCS_BUCKET_NAME=<this bucket>)
resource "google_storage_bucket" "uploads" {
  name     = "${var.project_id}-${local.name_prefix}-uploads"
  location = var.region

  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"

  versioning {
    enabled = var.environment == "prod"
  }

  cors {
    origin          = ["*"]
    method          = ["GET", "PUT", "POST", "DELETE"]
    response_header = ["*"]
    max_age_seconds = 3600
  }

  labels = local.labels

  depends_on = [google_project_service.apis]
}
