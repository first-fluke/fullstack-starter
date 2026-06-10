# Firestore Database
# Native mode Firestore for real-time data synchronization
resource "google_firestore_database" "default" {
  project     = var.project_id
  name        = "(default)"
  location_id = var.region
  type        = "FIRESTORE_NATIVE"

  # Enable delete protection in production for data safety
  delete_protection_state = var.environment == "prod" ? "DELETE_PROTECTION_ENABLED" : "DELETE_PROTECTION_DISABLED"

  # Allow deletion when running terraform destroy
  deletion_policy = "DELETE"

  depends_on = [google_project_service.apis]
}
