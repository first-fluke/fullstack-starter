# Global IP for Load Balancer
resource "google_compute_global_address" "main" {
  count = var.domain != "" ? 1 : 0
  name  = "${local.name_prefix}-ip"
}

# SSL Certificate (managed by Google)
resource "google_compute_managed_ssl_certificate" "main" {
  count = var.domain != "" ? 1 : 0
  name  = "${local.name_prefix}-cert"

  managed {
    domains = [
      var.domain,
      "${var.api_subdomain}.${var.domain}",
    ]
  }
}

# Backend Service for Web (Cloud Run NEG)
resource "google_compute_region_network_endpoint_group" "web" {
  count                 = var.domain != "" ? 1 : 0
  name                  = "${local.name_prefix}-web-neg"
  network_endpoint_type = "SERVERLESS"
  region                = var.region

  cloud_run {
    service = google_cloud_run_v2_service.web.name
  }
}

resource "google_compute_backend_service" "web" {
  count           = var.domain != "" ? 1 : 0
  name            = "${local.name_prefix}-web-backend"
  protocol        = "HTTPS"
  timeout_sec     = 30
  security_policy = google_compute_security_policy.main[0].id

  backend {
    group = google_compute_region_network_endpoint_group.web[0].id
  }

  enable_cdn = true

  cdn_policy {
    cache_mode                   = "CACHE_ALL_STATIC"
    default_ttl                  = 3600
    max_ttl                      = 86400
    client_ttl                   = 3600
    negative_caching             = true
    serve_while_stale            = 86400
    signed_url_cache_max_age_sec = 0

    cache_key_policy {
      include_host         = true
      include_protocol     = true
      include_query_string = true
    }
  }

  log_config {
    enable      = true
    sample_rate = 1.0
  }
}

# Backend Service for API (Cloud Run NEG)
resource "google_compute_region_network_endpoint_group" "api" {
  count                 = var.domain != "" ? 1 : 0
  name                  = "${local.name_prefix}-api-neg"
  network_endpoint_type = "SERVERLESS"
  region                = var.region

  cloud_run {
    service = google_cloud_run_v2_service.api.name
  }
}

resource "google_compute_backend_service" "api" {
  count           = var.domain != "" ? 1 : 0
  name            = "${local.name_prefix}-api-backend"
  protocol        = "HTTPS"
  timeout_sec     = 60
  security_policy = google_compute_security_policy.main[0].id

  backend {
    group = google_compute_region_network_endpoint_group.api[0].id
  }

  log_config {
    enable      = true
    sample_rate = 1.0
  }
}

# Backend Bucket for Static Assets
resource "google_compute_backend_bucket" "static" {
  count       = var.domain != "" ? 1 : 0
  name        = "${local.name_prefix}-static-backend"
  bucket_name = google_storage_bucket.static.name
  enable_cdn  = true

  cdn_policy {
    cache_mode        = "CACHE_ALL_STATIC"
    default_ttl       = 86400
    max_ttl           = 604800
    client_ttl        = 86400
    negative_caching  = true
    serve_while_stale = 86400
  }
}

# URL Map
resource "google_compute_url_map" "main" {
  count           = var.domain != "" ? 1 : 0
  name            = "${local.name_prefix}-url-map"
  default_service = google_compute_backend_service.web[0].id

  host_rule {
    hosts        = ["${var.api_subdomain}.${var.domain}"]
    path_matcher = "api"
  }

  host_rule {
    hosts        = [var.domain]
    path_matcher = "web"
  }

  path_matcher {
    name            = "api"
    default_service = google_compute_backend_service.api[0].id
  }

  path_matcher {
    name            = "web"
    default_service = google_compute_backend_service.web[0].id

    path_rule {
      paths   = ["/static/*"]
      service = google_compute_backend_bucket.static[0].id
    }
  }
}

# HTTPS Proxy
resource "google_compute_target_https_proxy" "main" {
  count            = var.domain != "" ? 1 : 0
  name             = "${local.name_prefix}-https-proxy"
  url_map          = google_compute_url_map.main[0].id
  ssl_certificates = [google_compute_managed_ssl_certificate.main[0].id]
}

# Global Forwarding Rule
resource "google_compute_global_forwarding_rule" "https" {
  count      = var.domain != "" ? 1 : 0
  name       = "${local.name_prefix}-https-rule"
  target     = google_compute_target_https_proxy.main[0].id
  port_range = "443"
  ip_address = google_compute_global_address.main[0].address

  labels = local.labels
}

# HTTP to HTTPS Redirect
resource "google_compute_url_map" "redirect" {
  count = var.domain != "" ? 1 : 0
  name  = "${local.name_prefix}-redirect"

  default_url_redirect {
    https_redirect         = true
    redirect_response_code = "MOVED_PERMANENTLY_DEFAULT"
    strip_query            = false
  }
}

resource "google_compute_target_http_proxy" "redirect" {
  count   = var.domain != "" ? 1 : 0
  name    = "${local.name_prefix}-http-proxy"
  url_map = google_compute_url_map.redirect[0].id
}

resource "google_compute_global_forwarding_rule" "http" {
  count      = var.domain != "" ? 1 : 0
  name       = "${local.name_prefix}-http-rule"
  target     = google_compute_target_http_proxy.redirect[0].id
  port_range = "80"
  ip_address = google_compute_global_address.main[0].address

  labels = local.labels
}
