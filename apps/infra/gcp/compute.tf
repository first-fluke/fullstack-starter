# Cloud Run Service - API
resource "google_cloud_run_v2_service" "api" {
  name     = "${local.name_prefix}-api"
  location = var.region
  ingress  = "INGRESS_TRAFFIC_ALL"

  template {
    timeout         = "120s"
    service_account = google_service_account.api.email

    scaling {
      min_instance_count = var.api_min_instances
      max_instance_count = var.api_max_instances
    }

    vpc_access {
      network_interfaces {
        network    = google_compute_network.main.id
        subnetwork = google_compute_subnetwork.main.id
      }
      egress = "PRIVATE_RANGES_ONLY"
    }

    containers {
      image = local.api_image

      resources {
        limits = {
          cpu    = var.api_cpu
          memory = var.api_memory
        }
        cpu_idle          = true
        startup_cpu_boost = true
      }

      env {
        name  = "ENVIRONMENT"
        value = var.environment
      }

      env {
        name  = "DATABASE_HOST"
        value = google_sql_database_instance.main.private_ip_address
      }

      env {
        name  = "DATABASE_NAME"
        value = var.db_name
      }

      env {
        name  = "DATABASE_USER"
        value = var.db_user
      }

      env {
        name  = "DATABASE_PASSWORD"
        value = var.DATABASE_PASSWORD
      }

      env {
        name  = "REDIS_HOST"
        value = google_redis_instance.main.host
      }

      env {
        name  = "REDIS_PORT"
        value = tostring(google_redis_instance.main.port)
      }

      env {
        name  = "JWT_SECRET"
        value = var.JWT_SECRET
      }

      env {
        name  = "JWE_SECRET_KEY"
        value = var.JWT_SECRET
      }

      env {
        name  = "API_PUBLIC_URL"
        value = local.api_public_url
      }

      env {
        name  = "CORS_ORIGINS"
        value = jsonencode([local.web_public_url])
      }

      env {
        name  = "OAUTH_ALLOWED_WEB_ORIGINS"
        value = jsonencode([local.web_public_url])
      }

      env {
        name  = "WEBAUTHN_RP_ID"
        value = local.web_rp_id
      }

      env {
        name  = "WEBAUTHN_ORIGINS"
        value = jsonencode([local.web_public_url])
      }

      env {
        name  = "WEBAUTHN_ANDROID_SHA256_CERT_FINGERPRINTS"
        value = jsonencode(var.MOBILE_ANDROID_SHA256_CERT_FINGERPRINTS)
      }

      env {
        name  = "GOOGLE_CLIENT_ID"
        value = var.GOOGLE_CLIENT_ID
      }

      env {
        name  = "GOOGLE_CLIENT_SECRET"
        value = var.GOOGLE_CLIENT_SECRET
      }

      env {
        name  = "GITHUB_CLIENT_ID"
        value = var.GITHUB_CLIENT_ID
      }

      env {
        name  = "GITHUB_CLIENT_SECRET"
        value = var.GITHUB_CLIENT_SECRET
      }

      env {
        name  = "FACEBOOK_CLIENT_ID"
        value = var.FACEBOOK_CLIENT_ID
      }

      env {
        name  = "FACEBOOK_CLIENT_SECRET"
        value = var.FACEBOOK_CLIENT_SECRET
      }


      env {
        name  = "STORAGE_BUCKET"
        value = google_storage_bucket.uploads.name
      }

      startup_probe {
        http_get {
          path = "/health"
        }
        initial_delay_seconds = 5
        period_seconds        = 10
        failure_threshold     = 3
      }

      liveness_probe {
        http_get {
          path = "/health"
        }
        period_seconds    = 30
        failure_threshold = 3
      }
    }
  }

  labels = local.labels
}

# Cloud Run Service - Web
resource "google_cloud_run_v2_service" "web" {
  name     = "${local.name_prefix}-web"
  location = var.region
  ingress  = "INGRESS_TRAFFIC_ALL"

  template {
    timeout         = "120s"
    service_account = google_service_account.web.email

    scaling {
      min_instance_count = var.web_min_instances
      max_instance_count = var.web_max_instances
    }

    containers {
      image = local.web_image

      resources {
        limits = {
          cpu    = var.web_cpu
          memory = var.web_memory
        }
        cpu_idle          = true
        startup_cpu_boost = true
      }

      env {
        name  = "NEXT_PUBLIC_API_URL"
        value = local.api_public_url
      }

      env {
        name  = "MOBILE_ANDROID_PACKAGE_NAME"
        value = var.MOBILE_ANDROID_PACKAGE_NAME
      }

      env {
        name  = "MOBILE_ANDROID_SHA256_CERT_FINGERPRINTS"
        value = join(",", var.MOBILE_ANDROID_SHA256_CERT_FINGERPRINTS)
      }

      env {
        name  = "MOBILE_APPLE_APP_IDS"
        value = join(",", var.MOBILE_APPLE_APP_IDS)
      }

      startup_probe {
        http_get {
          path = "/api/health"
        }
        initial_delay_seconds = 5
        period_seconds        = 10
        failure_threshold     = 3
      }

      liveness_probe {
        http_get {
          path = "/api/health"
        }
        period_seconds    = 30
        failure_threshold = 3
      }
    }
  }

  labels = local.labels
}

# Cloud Run Service - Worker
resource "google_cloud_run_v2_service" "worker" {
  name     = "${local.name_prefix}-worker"
  location = var.region
  ingress  = "INGRESS_TRAFFIC_INTERNAL_ONLY"

  template {
    timeout         = "120s"
    service_account = google_service_account.worker.email

    scaling {
      min_instance_count = var.worker_min_instances
      max_instance_count = var.worker_max_instances
    }

    vpc_access {
      network_interfaces {
        network    = google_compute_network.main.id
        subnetwork = google_compute_subnetwork.main.id
      }
      egress = "PRIVATE_RANGES_ONLY"
    }

    containers {
      image = local.worker_image

      resources {
        limits = {
          cpu    = var.worker_cpu
          memory = var.worker_memory
        }
        cpu_idle          = true
        startup_cpu_boost = true
      }

      env {
        name  = "ENVIRONMENT"
        value = var.environment
      }

      env {
        name  = "DATABASE_HOST"
        value = google_sql_database_instance.main.private_ip_address
      }

      env {
        name  = "DATABASE_NAME"
        value = var.db_name
      }

      env {
        name  = "DATABASE_USER"
        value = var.db_user
      }

      env {
        name  = "DATABASE_PASSWORD"
        value = var.DATABASE_PASSWORD
      }

      env {
        name  = "REDIS_HOST"
        value = google_redis_instance.main.host
      }

      env {
        name  = "REDIS_PORT"
        value = tostring(google_redis_instance.main.port)
      }

      env {
        name  = "STORAGE_BUCKET"
        value = google_storage_bucket.uploads.name
      }

      startup_probe {
        http_get {
          path = "/health"
        }
        initial_delay_seconds = 5
        period_seconds        = 10
        failure_threshold     = 3
      }
    }
  }

  labels = local.labels
}

# Allow public access to API
resource "google_cloud_run_v2_service_iam_member" "api_public" {
  location = google_cloud_run_v2_service.api.location
  name     = google_cloud_run_v2_service.api.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}

# Allow public access to Web
resource "google_cloud_run_v2_service_iam_member" "web_public" {
  location = google_cloud_run_v2_service.web.location
  name     = google_cloud_run_v2_service.web.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}

# Allow Cloud Tasks to invoke Worker
resource "google_cloud_run_v2_service_iam_member" "worker_tasks" {
  location = google_cloud_run_v2_service.worker.location
  name     = google_cloud_run_v2_service.worker.name
  role     = "roles/run.invoker"
  member   = "serviceAccount:${google_service_account.tasks.email}"
}

# Allow Pub/Sub to invoke Worker
resource "google_cloud_run_v2_service_iam_member" "worker_pubsub" {
  location = google_cloud_run_v2_service.worker.location
  name     = google_cloud_run_v2_service.worker.name
  role     = "roles/run.invoker"
  member   = "serviceAccount:${google_service_account.pubsub.email}"
}
