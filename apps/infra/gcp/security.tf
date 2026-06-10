# Enable required APIs
resource "google_project_service" "apis" {
  for_each = toset([
    "run.googleapis.com",
    "artifactregistry.googleapis.com",
    "secretmanager.googleapis.com",
    "sqladmin.googleapis.com",
    "redis.googleapis.com",
    "vpcaccess.googleapis.com",
    "servicenetworking.googleapis.com",
    "cloudtasks.googleapis.com",
    "cloudscheduler.googleapis.com",
    "pubsub.googleapis.com",
    "compute.googleapis.com",
    "iamcredentials.googleapis.com",
    "iam.googleapis.com",
    "firestore.googleapis.com",
    "aiplatform.googleapis.com",
  ])

  project = var.project_id
  service = each.value

  disable_on_destroy = false
}

# Cloud Armor Security Policy (for HTTPS Load Balancer)
resource "google_compute_security_policy" "main" {
  count = var.domain != "" ? 1 : 0
  name  = "${local.name_prefix}-security-policy"

  # Default rule - allow all traffic
  rule {
    action   = "allow"
    priority = "2147483647"

    match {
      versioned_expr = "SRC_IPS_V1"
      config {
        src_ip_ranges = ["*"]
      }
    }

    description = "Default allow rule"
  }

  # Rate limiting rule
  rule {
    action   = "throttle"
    priority = "1000"

    match {
      versioned_expr = "SRC_IPS_V1"
      config {
        src_ip_ranges = ["*"]
      }
    }

    rate_limit_options {
      conform_action = "allow"
      exceed_action  = "deny(429)"

      rate_limit_threshold {
        count        = 1000
        interval_sec = 60
      }
    }

    description = "Rate limiting - 1000 requests per minute"
  }

  # Block known bad IPs (example - customize as needed)
  rule {
    action   = "deny(403)"
    priority = "100"

    match {
      expr {
        expression = "origin.region_code == 'XX'"
      }
    }

    description = "Block traffic from specific regions"
    preview     = true # Enable preview mode first
  }

  # XSS protection
  rule {
    action   = "deny(403)"
    priority = "200"

    match {
      expr {
        expression = "evaluatePreconfiguredExpr('xss-stable')"
      }
    }

    description = "XSS protection"
  }

  # SQL injection protection
  rule {
    action   = "deny(403)"
    priority = "300"

    match {
      expr {
        expression = "evaluatePreconfiguredExpr('sqli-stable')"
      }
    }

    description = "SQL injection protection"
  }
}

# Security policy is attached via the security_policy argument on
# google_compute_backend_service.web / .api in cdn.tf
