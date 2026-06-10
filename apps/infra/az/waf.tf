# Front Door WAF policy (mirrors aws/waf.tf / GCP Cloud Armor).
# Rate-limit custom rules work on Standard_AzureFrontDoor; managed rule sets
# (Microsoft_DefaultRuleSet / Bot Manager — the XSS/SQLi equivalent of the AWS
# managed groups) require the Premium SKU. To enable them, upgrade both the
# profile and this policy to Premium_AzureFrontDoor and add:
#   managed_rule {
#     type    = "Microsoft_DefaultRuleSet"
#     version = "2.1"
#     action  = "Block"
#   }
resource "azurerm_cdn_frontdoor_firewall_policy" "main" {
  count = var.enable_waf ? 1 : 0

  # WAF policy names must be alphanumeric only
  name                = "${local.alnum_prefix}waf"
  resource_group_name = azurerm_resource_group.main.name
  sku_name            = azurerm_cdn_frontdoor_profile.main.sku_name
  enabled             = true
  mode                = "Prevention"

  # Rate limiting - ~1000 requests per minute per client IP
  # (Front Door groups rate-limit counters by socket address)
  custom_rule {
    name                           = "RateLimit"
    enabled                        = true
    priority                       = 1
    type                           = "RateLimitRule"
    action                         = "Block"
    rate_limit_duration_in_minutes = 1
    rate_limit_threshold           = 1000

    # Match-all condition: rate limit rules still require a match_condition
    match_condition {
      match_variable = "RemoteAddr"
      operator       = "IPMatch"
      match_values   = ["0.0.0.0/0"]
    }
  }

  tags = local.common_tags
}

resource "azurerm_cdn_frontdoor_security_policy" "main" {
  count = var.enable_waf ? 1 : 0

  name                     = "${local.name_prefix}-waf"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.main.id

  security_policies {
    firewall {
      cdn_frontdoor_firewall_policy_id = azurerm_cdn_frontdoor_firewall_policy.main[0].id

      association {
        domain {
          cdn_frontdoor_domain_id = azurerm_cdn_frontdoor_endpoint.static.id
        }
        patterns_to_match = ["/*"]
      }
    }
  }
}
