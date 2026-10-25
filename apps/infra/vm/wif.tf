# Optional keyless identity for GitHub Actions to push images. Created only
# when github_repository is set; deploys still run from an operator's
# workstation through IAP (see ansible/).

resource "google_iam_workload_identity_pool" "github" {
  for_each = local.github_enabled

  workload_identity_pool_id = "${local.name_prefix}-vm-pool"
  display_name              = "${var.app_name} VM Pool"
  description               = "Workload Identity Pool for ${var.app_name} GitHub Actions image pushes"

  depends_on = [google_project_service.apis]
}

resource "google_iam_workload_identity_pool_provider" "github" {
  for_each = local.github_enabled

  workload_identity_pool_id          = google_iam_workload_identity_pool.github[each.key].workload_identity_pool_id
  workload_identity_pool_provider_id = "github-provider"
  display_name                       = "GitHub Actions Provider"
  attribute_condition                = "assertion.repository == '${var.github_repository}'"

  attribute_mapping = {
    "google.subject"       = "assertion.sub"
    "attribute.actor"      = "assertion.actor"
    "attribute.repository" = "assertion.repository"
  }

  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }
}

resource "google_service_account" "github" {
  for_each = local.github_enabled

  account_id   = "${local.name_prefix}-vm-ci"
  display_name = "GitHub Actions (${var.app_name} VM images)"
  description  = "Pushes application images to Artifact Registry"

  depends_on = [google_project_service.apis]
}

resource "google_service_account_iam_member" "github_wif" {
  for_each = local.github_enabled

  service_account_id = google_service_account.github[each.key].name
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.github[each.key].name}/attribute.repository/${var.github_repository}"
}

resource "google_artifact_registry_repository_iam_member" "github_writer" {
  for_each = local.github_enabled

  project    = google_artifact_registry_repository.main.project
  location   = google_artifact_registry_repository.main.location
  repository = google_artifact_registry_repository.main.name
  role       = "roles/artifactregistry.writer"
  member     = "serviceAccount:${google_service_account.github[each.key].email}"
}
