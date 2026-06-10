# WAF on the Load Balancer (mirrors aws/waf.tf: rate limiting per client IP).
# OCI WAF request rate limiting counts requests per unique client IP by
# design — no aggregate_key_type equivalent is needed.
resource "oci_waf_web_app_firewall_policy" "main" {
  count = var.enable_waf ? 1 : 0

  compartment_id = oci_identity_compartment.main.id
  display_name   = "${local.name_prefix}-waf"

  actions {
    name = "allow"
    type = "ALLOW"
  }

  actions {
    name = "rate-limit-429"
    type = "RETURN_HTTP_RESPONSE"
    code = 429

    body {
      type = "STATIC_TEXT"
      text = "{\"error\":\"rate limit exceeded\"}"
    }

    headers {
      name  = "Content-Type"
      value = "application/json"
    }
  }

  # ~1000 requests per minute per client IP (aws/waf.tf: 5000 per 5 minutes)
  request_rate_limiting {
    rules {
      name        = "rate-limit"
      type        = "REQUEST_RATE_LIMITING"
      action_name = "rate-limit-429"

      configurations {
        period_in_seconds          = 60
        requests_limit             = 1000
        action_duration_in_seconds = 60
      }
    }
  }

  # XSS/SQLi protection rules (AWSManagedRulesCommonRuleSet equivalent) are
  # available as OCI WAF protection capabilities (request_protection block
  # with OCI-managed capability keys, e.g. 941* XSS / 942* SQLi groups) —
  # add them per-app once traffic patterns are known to avoid false positives.

  freeform_tags = local.common_tags
}

resource "oci_waf_web_app_firewall" "lb" {
  count = var.enable_waf ? 1 : 0

  compartment_id             = oci_identity_compartment.main.id
  display_name               = "${local.name_prefix}-waf"
  backend_type               = "LOAD_BALANCER"
  load_balancer_id           = oci_load_balancer_load_balancer.main.id
  web_app_firewall_policy_id = oci_waf_web_app_firewall_policy.main[0].id

  freeform_tags = local.common_tags
}
