# OCIR container repositories (mirror aws/ecr.tf).
# OCIR creates repositories implicitly on first push, but they land in the
# tenancy root compartment — creating them explicitly keeps them inside the
# stack compartment with the right visibility and tags.
resource "oci_artifacts_container_repository" "api" {
  compartment_id = oci_identity_compartment.main.id
  display_name   = "${var.app_name}/api"
  is_public      = false

  freeform_tags = local.common_tags
}

resource "oci_artifacts_container_repository" "web" {
  compartment_id = oci_identity_compartment.main.id
  display_name   = "${var.app_name}/web"
  is_public      = false

  freeform_tags = local.common_tags
}

resource "oci_artifacts_container_repository" "worker" {
  compartment_id = oci_identity_compartment.main.id
  display_name   = "${var.app_name}/worker"
  is_public      = false

  freeform_tags = local.common_tags
}

# Image retention (aws/ecr.tf keeps the last 10 images): OCIR has no
# per-repository lifecycle policy resource — image retention is a tenancy/
# compartment-level OCIR feature configured via the console or the
# `oci artifacts container image-retention` policies, not Terraform.
