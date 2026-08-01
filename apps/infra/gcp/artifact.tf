# Artifact Registry for Docker images
resource "google_artifact_registry_repository" "main" {
  location      = var.region
  repository_id = "${local.name_prefix}-images"
  description   = "Docker images for ${var.app_name}"
  format        = "DOCKER"

  # Retention mirrors the daily `acr purge` task in az/acr.tf: keep the two
  # newest versions per image, drop everything else. A KEEP policy here is only
  # an exemption from a DELETE policy — without "delete-superseded" below, the
  # keep-count rule expires nothing at all.
  cleanup_policies {
    id     = "keep-minimum-versions"
    action = "KEEP"

    most_recent_versions {
      keep_count = 2
    }
  }

  # locals.tf pins the initial Cloud Run revision to `:latest`, so it is exempt
  # the same way the ACR filters' hex-tag regex excludes it.
  cleanup_policies {
    id     = "keep-latest-tag"
    action = "KEEP"

    condition {
      tag_state    = "TAGGED"
      tag_prefixes = ["latest"]
    }
  }

  cleanup_policies {
    id     = "delete-superseded"
    action = "DELETE"

    condition {
      older_than = "86400s" # 1 day — a grace window for in-flight deploys
    }
  }

  labels = local.labels
}
