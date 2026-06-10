output "api_url" {
  description = "API Cloud Run URL"
  value       = google_cloud_run_v2_service.api.uri
}

output "web_url" {
  description = "Web Cloud Run URL"
  value       = google_cloud_run_v2_service.web.uri
}

output "worker_url" {
  description = "Worker Cloud Run URL (internal)"
  value       = google_cloud_run_v2_service.worker.uri
}

output "database_connection_name" {
  description = "Cloud SQL connection name"
  value       = google_sql_database_instance.main.connection_name
}

output "database_private_ip" {
  description = "Cloud SQL private IP"
  value       = google_sql_database_instance.main.private_ip_address
}

output "redis_host" {
  description = "Redis host"
  value       = google_redis_instance.main.host
}

output "redis_port" {
  description = "Redis port"
  value       = google_redis_instance.main.port
}

output "uploads_bucket" {
  description = "Uploads storage bucket name"
  value       = google_storage_bucket.uploads.name
}

output "static_bucket" {
  description = "Static assets storage bucket name"
  value       = google_storage_bucket.static.name
}

output "artifact_registry_url" {
  description = "Artifact Registry URL"
  value       = "${var.region}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.main.repository_id}"
}

output "pubsub_topic" {
  description = "Main Pub/Sub topic for async tasks"
  value       = google_pubsub_topic.main.name
}

output "cloud_tasks_queue" {
  description = "Main Cloud Tasks queue"
  value       = google_cloud_tasks_queue.main.name
}

output "load_balancer_ip" {
  description = "Load Balancer IP address"
  value       = var.domain != "" ? google_compute_global_address.main[0].address : null
}

output "workload_identity_provider" {
  description = "Workload Identity Provider for GitHub Actions"
  value       = google_iam_workload_identity_pool_provider.github_provider.name
}

output "github_service_account" {
  description = "GitHub Actions service account email"
  value       = google_service_account.github.email
}
