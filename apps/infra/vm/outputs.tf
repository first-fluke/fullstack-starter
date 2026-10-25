output "instance_name" {
  description = "VM instance name (ansible_host in ansible/inventory.yml)"
  value       = google_compute_instance.main.name
}

output "public_ip" {
  description = "Static public IP. Create A records for domain and api_domain pointing here."
  value       = google_compute_address.main.address
}

output "ssh_command" {
  description = "Interactive shell through IAP with OS Login"
  value       = "gcloud compute ssh ${google_compute_instance.main.name} --project=${var.project_id} --zone=${var.zone} --tunnel-through-iap"
}

output "data_device" {
  description = "Block device of the data disk (data_device in ansible/group_vars)"
  value       = local.data_device_path
}

output "backup_bucket" {
  description = "Backup bucket name (backup_bucket in ansible/group_vars)"
  value       = google_storage_bucket.backups.name
}

output "uploads_bucket" {
  description = "Application uploads bucket (GCS_BUCKET_NAME in app.env)"
  value       = google_storage_bucket.uploads.name
}

output "artifact_registry_url" {
  description = "Docker repository URL for api, web and worker images"
  value       = "${var.region}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.main.repository_id}"
}

output "vm_service_account" {
  description = "Service account the VM and its containers run as"
  value       = google_service_account.vm.email
}

output "workload_identity_provider" {
  description = "Workload Identity Provider for GitHub Actions (null when github_repository is empty)"
  value       = try(one(values(google_iam_workload_identity_pool_provider.github)).name, null)
}

output "github_service_account" {
  description = "GitHub Actions service account email (null when github_repository is empty)"
  value       = try(one(values(google_service_account.github)).email, null)
}
