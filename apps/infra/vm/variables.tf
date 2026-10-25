variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "region" {
  description = "GCP region"
  type        = string
  default     = "asia-northeast3"
}

variable "zone" {
  description = "GCP zone for the VM and its data disk"
  type        = string
  default     = "asia-northeast3-a"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "environment must be dev, staging or prod."
  }
}

variable "app_name" {
  description = "Application name prefix for resources. Must match app_name in ansible/group_vars."
  type        = string
  default     = "fullstack-starter"
}

# Compute
variable "machine_type" {
  description = "VM machine type. e2-small (2 GB) runs postgres + api + web + worker; images must be built off-host."
  type        = string
  default     = "e2-small"
}

variable "boot_disk_gb" {
  description = "Boot disk size in GB"
  type        = number
  default     = 20
}

variable "data_disk_gb" {
  description = "Dedicated persistent disk for PostgreSQL, Redis and local backups"
  type        = number
  default     = 30
}

variable "deletion_protection" {
  description = "Protect the VM from accidental terraform destroy"
  type        = bool
  default     = true
}

variable "snapshot_retention_days" {
  description = "Days to keep daily snapshots of the data disk"
  type        = number
  default     = 7
}

variable "snapshot_start_time" {
  description = "UTC start time (HH:MM) of the daily data disk snapshot"
  type        = string
  default     = "18:00"
}

# Network
variable "vpc_cidr" {
  description = "CIDR block for the VM subnet"
  type        = string
  default     = "10.42.0.0/24"
}

# Access
variable "operator_members" {
  description = "IAM members allowed to SSH through IAP with OS Login, e.g. [\"user:operator@example.com\"]. No SSH public keys are used."
  type        = set(string)
  default     = []
}

# Storage
variable "backup_retention_days" {
  description = "Days to keep database backups in the backup bucket"
  type        = number
  default     = 30
}

# Registry
variable "artifact_keep_count" {
  description = "Most recent image versions to keep per Artifact Registry package"
  type        = number
  default     = 2

  validation {
    condition     = var.artifact_keep_count >= 1 && floor(var.artifact_keep_count) == var.artifact_keep_count
    error_message = "artifact_keep_count must be a positive whole number."
  }
}

# CI/CD (optional)
variable "github_repository" {
  description = "GitHub repository in format 'owner/repo'. When set, creates a Workload Identity pool and a service account that can push images. Leave empty when images are pushed from a workstation."
  type        = string
  default     = ""
}
