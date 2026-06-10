# Cloud Storage Bucket for uploads
resource "google_storage_bucket" "uploads" {
  name     = "${var.project_id}-${local.name_prefix}-uploads"
  location = var.region

  uniform_bucket_level_access = true

  versioning {
    enabled = var.environment == "prod"
  }

  lifecycle_rule {
    condition {
      age = 90
    }
    action {
      type = "Delete"
    }
  }

  cors {
    origin          = ["*"]
    method          = ["GET", "PUT", "POST", "DELETE"]
    response_header = ["*"]
    max_age_seconds = 3600
  }

  labels = local.labels
}

# Cloud Storage Bucket for static assets (CDN origin)
resource "google_storage_bucket" "static" {
  name     = "${var.project_id}-${local.name_prefix}-static"
  location = var.region

  uniform_bucket_level_access = true

  website {
    main_page_suffix = "index.html"
    not_found_page   = "404.html"
  }

  cors {
    origin          = ["*"]
    method          = ["GET", "HEAD"]
    response_header = ["*"]
    max_age_seconds = 86400
  }

  labels = local.labels
}

# Make static bucket publicly readable
resource "google_storage_bucket_iam_member" "static_public" {
  bucket = google_storage_bucket.static.name
  role   = "roles/storage.objectViewer"
  member = "allUsers"
}
