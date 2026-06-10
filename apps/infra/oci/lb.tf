# Load Balancer (mirrors aws/alb.tf: flexible shape, host/path routing)
resource "oci_load_balancer_load_balancer" "main" {
  compartment_id = oci_identity_compartment.main.id
  display_name   = local.name_prefix

  shape = "flexible"
  shape_details {
    minimum_bandwidth_in_mbps = var.lb_min_bandwidth_mbps
    maximum_bandwidth_in_mbps = var.lb_max_bandwidth_mbps
  }

  is_private                 = false
  subnet_ids                 = [oci_core_subnet.public.id]
  network_security_group_ids = [oci_core_network_security_group.lb.id]

  freeform_tags = local.common_tags
}

# Backend Sets (target group equivalents)
resource "oci_load_balancer_backend_set" "api" {
  load_balancer_id = oci_load_balancer_load_balancer.main.id
  name             = "api"
  policy           = "ROUND_ROBIN"

  health_checker {
    protocol          = "HTTP"
    port              = 8000
    url_path          = "/health"
    interval_ms       = 30000
    timeout_in_millis = 5000
    retries           = 3
    return_code       = 200
  }
}

resource "oci_load_balancer_backend_set" "web" {
  load_balancer_id = oci_load_balancer_load_balancer.main.id
  name             = "web"
  policy           = "ROUND_ROBIN"

  health_checker {
    protocol          = "HTTP"
    port              = 3000
    url_path          = "/api/health"
    interval_ms       = 30000
    timeout_in_millis = 5000
    retries           = 3
    return_code       = 200
  }
}

# Backends point at container instance private IPs (target_type "ip" parity)
resource "oci_load_balancer_backend" "api" {
  count = var.api_count

  load_balancer_id = oci_load_balancer_load_balancer.main.id
  backendset_name  = oci_load_balancer_backend_set.api.name
  ip_address       = data.oci_core_vnic.api[count.index].private_ip_address
  port             = 8000
}

resource "oci_load_balancer_backend" "web" {
  count = var.web_count

  load_balancer_id = oci_load_balancer_load_balancer.main.id
  backendset_name  = oci_load_balancer_backend_set.web.name
  ip_address       = data.oci_core_vnic.web[count.index].private_ip_address
  port             = 3000
}

# Routing policies replace the deprecated path_route_set resources.
# With a certificate: host-based routing (api.<domain> → api), like aws/alb.tf
resource "oci_load_balancer_load_balancer_routing_policy" "https" {
  count = var.certificate_ocid != "" ? 1 : 0

  load_balancer_id           = oci_load_balancer_load_balancer.main.id
  name                       = "https_routing"
  condition_language_version = "V1"

  rules {
    name      = "api_host"
    condition = "all(http.request.headers[(i 'host')] eq (i '${var.api_subdomain}.${var.domain}'))"

    actions {
      name             = "FORWARD_TO_BACKENDSET"
      backend_set_name = oci_load_balancer_backend_set.api.name
    }
  }
}

# Without a certificate: path-based routing on the HTTP listener
resource "oci_load_balancer_load_balancer_routing_policy" "http" {
  count = var.certificate_ocid == "" ? 1 : 0

  load_balancer_id           = oci_load_balancer_load_balancer.main.id
  name                       = "http_routing"
  condition_language_version = "V1"

  rules {
    name      = "api_paths"
    condition = "any(http.request.url.path sw '/api/v1', http.request.url.path eq '/health', http.request.url.path eq '/docs', http.request.url.path eq '/openapi.json')"

    actions {
      name             = "FORWARD_TO_BACKENDSET"
      backend_set_name = oci_load_balancer_backend_set.api.name
    }
  }
}

# HTTP -> HTTPS redirect rule set (only when a certificate is provided)
resource "oci_load_balancer_rule_set" "https_redirect" {
  count = var.certificate_ocid != "" ? 1 : 0

  load_balancer_id = oci_load_balancer_load_balancer.main.id
  name             = "https_redirect"

  items {
    action = "REDIRECT"

    conditions {
      attribute_name  = "PATH"
      attribute_value = "/"
      operator        = "FORCE_LONGEST_PREFIX_MATCH"
    }

    redirect_uri {
      protocol = "HTTPS"
      host     = "{host}"
      port     = 443
      path     = "{path}"
      query    = "{query}"
    }

    response_code = 301
  }
}

# Listeners (HTTPS with redirect when certificate is provided)
resource "oci_load_balancer_listener" "http" {
  count = var.certificate_ocid != "" ? 1 : 0

  load_balancer_id         = oci_load_balancer_load_balancer.main.id
  name                     = "http"
  port                     = 80
  protocol                 = "HTTP"
  default_backend_set_name = oci_load_balancer_backend_set.web.name
  rule_set_names           = [oci_load_balancer_rule_set.https_redirect[0].name]
}

resource "oci_load_balancer_listener" "https" {
  count = var.certificate_ocid != "" ? 1 : 0

  load_balancer_id         = oci_load_balancer_load_balancer.main.id
  name                     = "https"
  port                     = 443
  protocol                 = "HTTP2"
  default_backend_set_name = oci_load_balancer_backend_set.web.name
  routing_policy_name      = oci_load_balancer_load_balancer_routing_policy.https[0].name

  ssl_configuration {
    certificate_ids         = [var.certificate_ocid]
    verify_peer_certificate = false
    protocols               = ["TLSv1.2", "TLSv1.3"]
  }
}

# HTTP-only listener (when no certificate)
resource "oci_load_balancer_listener" "http_direct" {
  count = var.certificate_ocid == "" ? 1 : 0

  load_balancer_id         = oci_load_balancer_load_balancer.main.id
  name                     = "http"
  port                     = 80
  protocol                 = "HTTP"
  default_backend_set_name = oci_load_balancer_backend_set.web.name
  routing_policy_name      = oci_load_balancer_load_balancer_routing_policy.http[0].name
}
