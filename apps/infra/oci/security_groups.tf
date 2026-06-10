# Network Security Groups (mirror aws/security_groups.tf scoping:
# LB 80/443 from world; apps 8000/3000 from LB; PG 5432 / Redis 6379 from apps)

# Load Balancer NSG
resource "oci_core_network_security_group" "lb" {
  compartment_id = oci_identity_compartment.main.id
  vcn_id         = oci_core_vcn.main.id
  display_name   = "${local.name_prefix}-lb-nsg"

  freeform_tags = local.common_tags
}

resource "oci_core_network_security_group_security_rule" "lb_http_ingress" {
  network_security_group_id = oci_core_network_security_group.lb.id
  description               = "HTTP"
  direction                 = "INGRESS"
  protocol                  = "6" # TCP
  source                    = "0.0.0.0/0"
  source_type               = "CIDR_BLOCK"

  tcp_options {
    destination_port_range {
      min = 80
      max = 80
    }
  }
}

resource "oci_core_network_security_group_security_rule" "lb_https_ingress" {
  network_security_group_id = oci_core_network_security_group.lb.id
  description               = "HTTPS"
  direction                 = "INGRESS"
  protocol                  = "6"
  source                    = "0.0.0.0/0"
  source_type               = "CIDR_BLOCK"

  tcp_options {
    destination_port_range {
      min = 443
      max = 443
    }
  }
}

resource "oci_core_network_security_group_security_rule" "lb_egress" {
  network_security_group_id = oci_core_network_security_group.lb.id
  description               = "All egress"
  direction                 = "EGRESS"
  protocol                  = "all"
  destination               = "0.0.0.0/0"
  destination_type          = "CIDR_BLOCK"
}

# Container Instances (apps) NSG
resource "oci_core_network_security_group" "apps" {
  compartment_id = oci_identity_compartment.main.id
  vcn_id         = oci_core_vcn.main.id
  display_name   = "${local.name_prefix}-apps-nsg"

  freeform_tags = local.common_tags
}

resource "oci_core_network_security_group_security_rule" "apps_api_from_lb" {
  network_security_group_id = oci_core_network_security_group.apps.id
  description               = "API from LB"
  direction                 = "INGRESS"
  protocol                  = "6"
  source                    = oci_core_network_security_group.lb.id
  source_type               = "NETWORK_SECURITY_GROUP"

  tcp_options {
    destination_port_range {
      min = 8000
      max = 8000
    }
  }
}

resource "oci_core_network_security_group_security_rule" "apps_web_from_lb" {
  network_security_group_id = oci_core_network_security_group.apps.id
  description               = "Web from LB"
  direction                 = "INGRESS"
  protocol                  = "6"
  source                    = oci_core_network_security_group.lb.id
  source_type               = "NETWORK_SECURITY_GROUP"

  tcp_options {
    destination_port_range {
      min = 3000
      max = 3000
    }
  }
}

resource "oci_core_network_security_group_security_rule" "apps_egress" {
  network_security_group_id = oci_core_network_security_group.apps.id
  description               = "All egress"
  direction                 = "EGRESS"
  protocol                  = "all"
  destination               = "0.0.0.0/0"
  destination_type          = "CIDR_BLOCK"
}

# Database NSG
resource "oci_core_network_security_group" "db" {
  compartment_id = oci_identity_compartment.main.id
  vcn_id         = oci_core_vcn.main.id
  display_name   = "${local.name_prefix}-db-nsg"

  freeform_tags = local.common_tags
}

resource "oci_core_network_security_group_security_rule" "db_from_apps" {
  network_security_group_id = oci_core_network_security_group.db.id
  description               = "PostgreSQL from apps"
  direction                 = "INGRESS"
  protocol                  = "6"
  source                    = oci_core_network_security_group.apps.id
  source_type               = "NETWORK_SECURITY_GROUP"

  tcp_options {
    destination_port_range {
      min = 5432
      max = 5432
    }
  }
}

# Redis NSG
resource "oci_core_network_security_group" "redis" {
  compartment_id = oci_identity_compartment.main.id
  vcn_id         = oci_core_vcn.main.id
  display_name   = "${local.name_prefix}-redis-nsg"

  freeform_tags = local.common_tags
}

resource "oci_core_network_security_group_security_rule" "redis_from_apps" {
  network_security_group_id = oci_core_network_security_group.redis.id
  description               = "Redis from apps"
  direction                 = "INGRESS"
  protocol                  = "6"
  source                    = oci_core_network_security_group.apps.id
  source_type               = "NETWORK_SECURITY_GROUP"

  tcp_options {
    destination_port_range {
      min = 6379
      max = 6379
    }
  }
}
