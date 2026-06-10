locals {
  name_prefix = "${var.app_name}-${var.environment}"

  labels = {
    app         = var.app_name
    environment = var.environment
    managed_by  = "terraform"
  }

  api_image    = "${var.region}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.main.repository_id}/api:latest"
  web_image    = "${var.region}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.main.repository_id}/web:latest"
  worker_image = "${var.region}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.main.repository_id}/worker:latest"
}
