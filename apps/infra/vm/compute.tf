# Static public IP (point the A records for domain and api_domain here)
resource "google_compute_address" "main" {
  name   = "${local.name_prefix}-ip"
  region = var.region
  labels = local.labels

  depends_on = [google_project_service.apis]
}

# Dedicated data disk: PostgreSQL, Redis and local backups live here, not on
# the boot disk, so the VM can be recreated without losing state.
resource "google_compute_disk" "data" {
  name   = local.data_device_name
  type   = "pd-balanced"
  zone   = var.zone
  size   = var.data_disk_gb
  labels = local.labels

  lifecycle {
    prevent_destroy = true
  }

  depends_on = [google_project_service.apis]
}

resource "google_compute_resource_policy" "snapshots" {
  name   = "${local.name_prefix}-daily-snapshot"
  region = var.region

  snapshot_schedule_policy {
    schedule {
      daily_schedule {
        days_in_cycle = 1
        start_time    = var.snapshot_start_time
      }
    }

    retention_policy {
      max_retention_days    = var.snapshot_retention_days
      on_source_disk_delete = "KEEP_AUTO_SNAPSHOTS"
    }

    snapshot_properties {
      labels = local.labels
    }
  }

  depends_on = [google_project_service.apis]
}

resource "google_compute_disk_resource_policy_attachment" "data" {
  name = google_compute_resource_policy.snapshots.name
  disk = google_compute_disk.data.name
  zone = var.zone
}

resource "google_compute_instance" "main" {
  name                      = local.name_prefix
  machine_type              = var.machine_type
  zone                      = var.zone
  labels                    = local.labels
  tags                      = [local.name_prefix]
  deletion_protection       = var.deletion_protection
  allow_stopping_for_update = true

  boot_disk {
    initialize_params {
      image  = "ubuntu-os-cloud/ubuntu-2404-lts-amd64"
      size   = var.boot_disk_gb
      type   = "pd-balanced"
      labels = local.labels
    }
  }

  attached_disk {
    source      = google_compute_disk.data.id
    device_name = local.data_device_name
  }

  network_interface {
    subnetwork = google_compute_subnetwork.main.id

    access_config {
      nat_ip = google_compute_address.main.address
    }
  }

  # Containers reach GCS / Artifact Registry through the VM's metadata ADC;
  # access is narrowed by IAM (iam.tf), not by scopes.
  service_account {
    email  = google_service_account.vm.email
    scopes = ["cloud-platform"]
  }

  metadata = {
    enable-oslogin         = "TRUE"
    block-project-ssh-keys = "TRUE"
    serial-port-enable     = "FALSE"
  }

  shielded_instance_config {
    enable_secure_boot          = true
    enable_vtpm                 = true
    enable_integrity_monitoring = true
  }

  depends_on = [google_project_service.apis]
}
