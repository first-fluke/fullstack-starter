# VCN (mirrors aws/vpc.tf)
resource "oci_core_vcn" "main" {
  compartment_id = oci_identity_compartment.main.id
  cidr_blocks    = [var.vcn_cidr]
  display_name   = local.name_prefix
  dns_label      = "main"

  freeform_tags = local.common_tags
}

# Internet Gateway (public subnet egress/ingress)
resource "oci_core_internet_gateway" "main" {
  compartment_id = oci_identity_compartment.main.id
  vcn_id         = oci_core_vcn.main.id
  display_name   = "${local.name_prefix}-igw"
  enabled        = true

  freeform_tags = local.common_tags
}

# NAT Gateway (private subnet egress)
resource "oci_core_nat_gateway" "main" {
  compartment_id = oci_identity_compartment.main.id
  vcn_id         = oci_core_vcn.main.id
  display_name   = "${local.name_prefix}-nat"

  freeform_tags = local.common_tags
}

# Service Gateway (private access to OCI services: Object Storage, OCIR, Queue)
data "oci_core_services" "all" {
  filter {
    name   = "name"
    values = ["All .* Services In Oracle Services Network"]
    regex  = true
  }
}

resource "oci_core_service_gateway" "main" {
  compartment_id = oci_identity_compartment.main.id
  vcn_id         = oci_core_vcn.main.id
  display_name   = "${local.name_prefix}-sgw"

  services {
    service_id = data.oci_core_services.all.services[0].id
  }

  freeform_tags = local.common_tags
}

# Route Tables
resource "oci_core_route_table" "public" {
  compartment_id = oci_identity_compartment.main.id
  vcn_id         = oci_core_vcn.main.id
  display_name   = "${local.name_prefix}-public-rt"

  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_internet_gateway.main.id
  }

  freeform_tags = local.common_tags
}

resource "oci_core_route_table" "private" {
  compartment_id = oci_identity_compartment.main.id
  vcn_id         = oci_core_vcn.main.id
  display_name   = "${local.name_prefix}-private-rt"

  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_nat_gateway.main.id
  }

  route_rules {
    destination       = data.oci_core_services.all.services[0].cidr_block
    destination_type  = "SERVICE_CIDR_BLOCK"
    network_entity_id = oci_core_service_gateway.main.id
  }

  freeform_tags = local.common_tags
}

# Subnets (regional). Security is enforced via NSGs (security_groups.tf), so
# the subnets keep the VCN default security list only.
resource "oci_core_subnet" "public" {
  compartment_id = oci_identity_compartment.main.id
  vcn_id         = oci_core_vcn.main.id
  cidr_block     = cidrsubnet(var.vcn_cidr, 8, 0)
  display_name   = "${local.name_prefix}-public"
  dns_label      = "public"
  route_table_id = oci_core_route_table.public.id

  prohibit_public_ip_on_vnic = false

  freeform_tags = local.common_tags
}

resource "oci_core_subnet" "private" {
  compartment_id = oci_identity_compartment.main.id
  vcn_id         = oci_core_vcn.main.id
  cidr_block     = cidrsubnet(var.vcn_cidr, 8, 10)
  display_name   = "${local.name_prefix}-private"
  dns_label      = "private"
  route_table_id = oci_core_route_table.private.id

  prohibit_public_ip_on_vnic = true

  freeform_tags = local.common_tags
}
