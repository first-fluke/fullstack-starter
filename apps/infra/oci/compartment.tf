# Child compartment for the whole stack (mirrors az/main.tf resource group)
resource "oci_identity_compartment" "main" {
  compartment_id = var.parent_compartment_ocid
  name           = local.name_prefix
  description    = "${var.app_name} ${var.environment} stack"

  # Allow `terraform destroy` to delete the compartment outside prod
  enable_delete = var.environment != "prod"

  freeform_tags = local.common_tags
}
