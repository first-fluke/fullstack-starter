# Get current project
data "google_project" "current" {
  project_id = var.project_id
}

# Service Account for API
resource "google_service_account" "api" {
  account_id   = "${local.name_prefix}-api"
  display_name = "API Service Account"
  description  = "Service account for API Cloud Run service"
}

# Service Account for Web
resource "google_service_account" "web" {
  account_id   = "${local.name_prefix}-web"
  display_name = "Web Service Account"
  description  = "Service account for Web Cloud Run service"
}

# Service Account for Worker
resource "google_service_account" "worker" {
  account_id   = "${local.name_prefix}-worker"
  display_name = "Worker Service Account"
  description  = "Service account for Worker Cloud Run service"
}

# Service Account for Cloud Tasks
resource "google_service_account" "tasks" {
  account_id   = "${local.name_prefix}-tasks"
  display_name = "Cloud Tasks Service Account"
  description  = "Service account for Cloud Tasks to invoke Cloud Run"
}

# Service Account for Pub/Sub
resource "google_service_account" "pubsub" {
  account_id   = "${local.name_prefix}-pubsub"
  display_name = "Pub/Sub Service Account"
  description  = "Service account for Pub/Sub to invoke Cloud Run"
}

# Service Account for GitHub Actions
resource "google_service_account" "github" {
  account_id   = "${local.name_prefix}-github"
  display_name = "GitHub Actions Service Account"
  description  = "Service account for GitHub Actions CI/CD"
}

# API Service Account Permissions
resource "google_project_iam_member" "api_storage" {
  project = var.project_id
  role    = "roles/storage.objectUser"
  member  = "serviceAccount:${google_service_account.api.email}"
}

resource "google_project_iam_member" "api_pubsub" {
  project = var.project_id
  role    = "roles/pubsub.publisher"
  member  = "serviceAccount:${google_service_account.api.email}"
}

resource "google_project_iam_member" "api_tasks" {
  project = var.project_id
  role    = "roles/cloudtasks.enqueuer"
  member  = "serviceAccount:${google_service_account.api.email}"
}

# Worker Service Account Permissions
resource "google_project_iam_member" "worker_storage" {
  project = var.project_id
  role    = "roles/storage.objectUser"
  member  = "serviceAccount:${google_service_account.worker.email}"
}

resource "google_project_iam_member" "worker_pubsub" {
  project = var.project_id
  role    = "roles/pubsub.publisher"
  member  = "serviceAccount:${google_service_account.worker.email}"
}

# GitHub Actions Permissions
resource "google_project_iam_member" "github_artifact_writer" {
  project = var.project_id
  role    = "roles/artifactregistry.writer"
  member  = "serviceAccount:${google_service_account.github.email}"
}

resource "google_project_iam_member" "github_run_developer" {
  project = var.project_id
  role    = "roles/run.developer"
  member  = "serviceAccount:${google_service_account.github.email}"
}

resource "google_project_iam_member" "github_sa_user" {
  project = var.project_id
  role    = "roles/iam.serviceAccountUser"
  member  = "serviceAccount:${google_service_account.github.email}"
}

# Vertex AI Service Identity
# This creates the Vertex AI Service Agent for the project
resource "google_project_service_identity" "vertex_ai" {
  provider = google-beta
  project  = var.project_id
  service  = "aiplatform.googleapis.com"

  depends_on = [google_project_service.apis]
}

# Grant Vertex AI Service Agent access to GCS buckets
# Required for model training, batch prediction, and artifact storage
resource "google_project_iam_member" "vertex_ai_storage" {
  project = var.project_id
  role    = "roles/storage.objectViewer"
  member  = "serviceAccount:${google_project_service_identity.vertex_ai.email}"
}
