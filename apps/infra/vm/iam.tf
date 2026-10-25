# Service account attached to the VM. Docker, the backup cron and the
# application containers all authenticate as this identity via metadata ADC.
resource "google_service_account" "vm" {
  account_id   = "${local.name_prefix}-vm"
  display_name = "${var.app_name} ${var.environment} VM"
  description  = "Runtime identity of the single Compute Engine VM"

  depends_on = [google_project_service.apis]
}

resource "google_project_iam_member" "vm_log_writer" {
  project = var.project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.vm.email}"
}

resource "google_project_iam_member" "vm_metric_writer" {
  project = var.project_id
  role    = "roles/monitoring.metricWriter"
  member  = "serviceAccount:${google_service_account.vm.email}"
}

# Pull application images
resource "google_artifact_registry_repository_iam_member" "vm_reader" {
  project    = google_artifact_registry_repository.main.project
  location   = google_artifact_registry_repository.main.location
  repository = google_artifact_registry_repository.main.name
  role       = "roles/artifactregistry.reader"
  member     = "serviceAccount:${google_service_account.vm.email}"
}

# Backups: write new objects and read them back for restore; never delete
# (the bucket lifecycle rule handles expiry).
resource "google_storage_bucket_iam_member" "vm_backup_writer" {
  bucket = google_storage_bucket.backups.name
  role   = "roles/storage.objectCreator"
  member = "serviceAccount:${google_service_account.vm.email}"
}

resource "google_storage_bucket_iam_member" "vm_backup_reader" {
  bucket = google_storage_bucket.backups.name
  role   = "roles/storage.objectViewer"
  member = "serviceAccount:${google_service_account.vm.email}"
}

# Application uploads (STORAGE_BACKEND=gcs)
resource "google_storage_bucket_iam_member" "vm_uploads_user" {
  bucket = google_storage_bucket.uploads.name
  role   = "roles/storage.objectUser"
  member = "serviceAccount:${google_service_account.vm.email}"
}

# Operators: IAP tunnel + OS Login (sudo) on this instance only
resource "google_iap_tunnel_instance_iam_member" "operator" {
  for_each = var.operator_members

  project  = var.project_id
  zone     = var.zone
  instance = google_compute_instance.main.name
  role     = "roles/iap.tunnelResourceAccessor"
  member   = each.value
}

resource "google_compute_instance_iam_member" "operator_login" {
  for_each = var.operator_members

  project       = var.project_id
  zone          = var.zone
  instance_name = google_compute_instance.main.name
  role          = "roles/compute.osAdminLogin"
  member        = each.value
}

# OS Login on an instance with an attached service account requires actAs
resource "google_service_account_iam_member" "operator_sa_user" {
  for_each = var.operator_members

  service_account_id = google_service_account.vm.name
  role               = "roles/iam.serviceAccountUser"
  member             = each.value
}
