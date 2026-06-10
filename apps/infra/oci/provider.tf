# Auth resolution: explicit tenancy/user/fingerprint/key vars win when set;
# otherwise the provider falls back to ~/.oci/config (config_file_profile).
provider "oci" {
  region              = var.region
  tenancy_ocid        = var.tenancy_ocid
  user_ocid           = var.user_ocid
  fingerprint         = var.fingerprint
  private_key_path    = var.private_key_path
  config_file_profile = var.config_file_profile

  # The oci provider has no default_tags mechanism — local.common_tags is
  # applied as freeform_tags on every taggable resource instead.
}
