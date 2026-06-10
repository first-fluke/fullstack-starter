output "compartment_id" {
  description = "Stack compartment OCID"
  value       = oci_identity_compartment.main.id
}

output "vcn_id" {
  description = "VCN OCID"
  value       = oci_core_vcn.main.id
}

output "lb_public_ip" {
  description = "Load balancer public IP"
  value       = local.lb_public_ip
}

output "api_url" {
  description = "API base URL"
  value       = local.api_url
}

output "web_url" {
  description = "Web base URL"
  value       = local.web_url
}

output "ocir_api_url" {
  description = "OCIR API repository URL"
  value       = local.api_image
}

output "ocir_web_url" {
  description = "OCIR Web repository URL"
  value       = local.web_image
}

output "ocir_worker_url" {
  description = "OCIR Worker repository URL"
  value       = local.worker_image
}

output "db_endpoint" {
  description = "PostgreSQL primary endpoint private IP"
  value       = oci_psql_db_system.main.network_details[0].primary_db_endpoint_private_ip
  sensitive   = true
}

output "redis_endpoint" {
  description = "OCI Cache primary endpoint FQDN"
  value       = oci_redis_redis_cluster.main.primary_fqdn
  sensitive   = true
}

output "uploads_bucket" {
  description = "Uploads bucket name"
  value       = oci_objectstorage_bucket.uploads.name
}

output "static_bucket" {
  description = "Static assets bucket name"
  value       = oci_objectstorage_bucket.static.name
}

output "objectstorage_namespace" {
  description = "Object Storage namespace (also the OCIR namespace)"
  value       = local.namespace
}

output "queue_ids" {
  description = "Queue OCIDs by name"
  value       = { for name in local.queue_names : name => oci_queue_queue.main[name].id }
}

output "queue_messages_endpoint" {
  description = "Queue messages endpoint (default queue)"
  value       = oci_queue_queue.main["default"].messages_endpoint
}

output "github_actions_service_user" {
  description = "Service user impersonated by GitHub Actions OIDC (null when identity_domain_ocid is unset)"
  value       = var.identity_domain_ocid != "" ? oci_identity_domains_user.github_actions[0].user_name : null
}

output "github_actions_client_id" {
  description = "OAuth client ID for the GitHub Actions token exchange (null when identity_domain_ocid is unset)"
  value       = var.identity_domain_ocid != "" ? oci_identity_domains_app.github_token_exchange[0].name : null
}

output "github_actions_token_endpoint" {
  description = "Identity domain token exchange endpoint for GitHub Actions (null when identity_domain_ocid is unset)"
  value       = var.identity_domain_ocid != "" ? "${data.oci_identity_domain.main[0].url}/oauth2/v1/token" : null
}
