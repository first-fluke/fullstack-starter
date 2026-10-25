# Artifact Registry for API, Web and Worker images. The VM pulls by immutable
# digest, so no tag is exempt from cleanup: keep the newest versions per
# package and drop everything older than the grace window.
resource "google_artifact_registry_repository" "main" {
  location      = var.region
  repository_id = "${local.name_prefix}-images"
  description   = "Docker images for ${var.app_name} (${var.environment} VM)"
  format        = "DOCKER"

  cleanup_policy_dry_run = false

  cleanup_policies {
    id     = "keep-minimum-versions"
    action = "KEEP"

    most_recent_versions {
      keep_count = var.artifact_keep_count
    }
  }

  cleanup_policies {
    id     = "delete-superseded"
    action = "DELETE"

    condition {
      tag_state  = "ANY"
      older_than = "259200s" # 3 days — grace window for rollbacks
    }
  }

  labels = local.labels

  depends_on = [google_project_service.apis]
}
