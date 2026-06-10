# OCI Cache (Redis) — mirrors aws/elasticache.tf
# The resource keeps its historical name oci_redis_redis_cluster even though
# the service is now branded "OCI Cache" and also offers Valkey engines.
resource "oci_redis_redis_cluster" "main" {
  compartment_id = oci_identity_compartment.main.id
  display_name   = local.name_prefix

  software_version   = var.redis_software_version
  cluster_mode       = "NONSHARDED"
  node_count         = var.redis_node_count
  node_memory_in_gbs = var.redis_memory_in_gbs

  subnet_id = oci_core_subnet.private.id
  nsg_ids   = [oci_core_network_security_group.redis.id]

  freeform_tags = local.common_tags
}

# OCI Cache endpoints are TLS-only — clients must connect with TLS
# (REDIS_TLS=true, port 6379), same as the AWS ElastiCache setup.
