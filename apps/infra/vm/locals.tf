locals {
  name_prefix = "${var.app_name}-${var.environment}"

  labels = {
    app         = var.app_name
    environment = var.environment
    managed_by  = "terraform"
  }

  # Compute Engine exposes attached disks as /dev/disk/by-id/google-<device_name>.
  data_device_name = "${local.name_prefix}-data"
  data_device_path = "/dev/disk/by-id/google-${local.data_device_name}"

  # for_each toggle for the optional GitHub Actions identity (for_each over count).
  github_enabled = var.github_repository != "" ? toset(["github"]) : toset([])
}
