locals {
  name_prefix = "${var.app_name}-${var.environment}"

  # The oci provider has no default_tags — apply these as freeform_tags on
  # every taggable resource (mirrors gcp/locals.tf labels and AWS default_tags)
  common_tags = {
    app         = var.app_name
    environment = var.environment
    managed_by  = "terraform"
  }

  # Queues mirror the GCP Cloud Tasks queue tiers (gcp/cloudtasks.tf) and the
  # AWS SQS trio (aws/sqs.tf)
  queue_names = ["default", "high-priority", "low-priority"]

  # OCIR image coordinates: <region>.ocir.io/<namespace>/<app>/<service>
  ocir_server    = "${var.region}.ocir.io"
  namespace      = data.oci_objectstorage_namespace.main.namespace
  ocir_repo_base = "${local.ocir_server}/${local.namespace}/${var.app_name}"

  api_image    = "${local.ocir_repo_base}/api:latest"
  web_image    = "${local.ocir_repo_base}/web:latest"
  worker_image = "${local.ocir_repo_base}/worker:latest"

  lb_public_ip = [for ip in oci_load_balancer_load_balancer.main.ip_address_details : ip.ip_address if ip.is_public][0]

  api_url = var.domain != "" ? "https://${var.api_subdomain}.${var.domain}" : "http://${local.lb_public_ip}"
  web_url = var.domain != "" ? "https://${var.domain}" : "http://${local.lb_public_ip}"
}

data "oci_objectstorage_namespace" "main" {
  compartment_id = var.tenancy_ocid
}

data "oci_identity_availability_domains" "main" {
  compartment_id = var.tenancy_ocid
}
