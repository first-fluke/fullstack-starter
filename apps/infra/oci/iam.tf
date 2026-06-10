# IAM: runtime identity for container instances + GitHub Actions OIDC
# (mirrors aws/iam.tf task role + OIDC provider/role and gcp/wif.tf)

# --- Runtime identity (ECS task role equivalent) -----------------------------
# Container instances support resource principals via dynamic groups, so the
# api/worker SDK clients authenticate without static keys.
resource "oci_identity_dynamic_group" "container_instances" {
  compartment_id = var.tenancy_ocid
  name           = "${local.name_prefix}-container-instances"
  description    = "Container instances in the ${local.name_prefix} compartment"
  matching_rule  = "ALL {resource.type = 'computecontainerinstance', resource.compartment.id = '${oci_identity_compartment.main.id}'}"

  freeform_tags = local.common_tags
}

resource "oci_identity_policy" "container_instances" {
  compartment_id = oci_identity_compartment.main.id
  name           = "${local.name_prefix}-container-instances"
  description    = "Runtime permissions for ${local.name_prefix} container instances (queues, object storage, image pulls)"

  statements = [
    "Allow dynamic-group ${oci_identity_dynamic_group.container_instances.name} to use queues in compartment ${oci_identity_compartment.main.name}",
    "Allow dynamic-group ${oci_identity_dynamic_group.container_instances.name} to manage objects in compartment ${oci_identity_compartment.main.name}",
    "Allow dynamic-group ${oci_identity_dynamic_group.container_instances.name} to read buckets in compartment ${oci_identity_compartment.main.name}",
    # Pull private OCIR images without image_pull_secrets
    "Allow dynamic-group ${oci_identity_dynamic_group.container_instances.name} to read repos in compartment ${oci_identity_compartment.main.name}",
  ]

  freeform_tags = local.common_tags
}

# Object Storage service permission required by the uploads lifecycle policy
# (storage.tf)
resource "oci_identity_policy" "object_lifecycle" {
  compartment_id = oci_identity_compartment.main.id
  name           = "${local.name_prefix}-object-lifecycle"
  description    = "Allow the Object Storage service to execute lifecycle policies"

  statements = [
    "Allow service objectstorage-${var.region} to manage object-family in compartment ${oci_identity_compartment.main.name}",
  ]

  freeform_tags = local.common_tags
}

# --- GitHub Actions OIDC (keyless CI) ----------------------------------------
# OCI supports keyless OIDC federation since 2025 via identity domain
# "identity propagation trust": the GitHub Actions JWT is exchanged for a
# short-lived User Principal Session Token (UPST) that impersonates a
# non-interactive service user. Set identity_domain_ocid to enable; when
# empty, no CI identity is provisioned (see README CI/CD section).
locals {
  oidc_enabled = var.identity_domain_ocid != "" ? 1 : 0
}

data "oci_identity_domain" "main" {
  count     = local.oidc_enabled
  domain_id = var.identity_domain_ocid
}

# Non-interactive service user impersonated by GitHub Actions
resource "oci_identity_domains_user" "github_actions" {
  count = local.oidc_enabled

  idcs_endpoint = data.oci_identity_domain.main[0].url
  schemas = [
    "urn:ietf:params:scim:schemas:core:2.0:User",
    "urn:ietf:params:scim:schemas:oracle:idcs:extension:user:User",
  ]

  user_name    = "${local.name_prefix}-github-actions"
  display_name = "${local.name_prefix} GitHub Actions"

  emails {
    type    = "work"
    value   = "github-actions+${var.environment}@${var.app_name}.invalid"
    primary = true
  }

  urnietfparamsscimschemasoracleidcsextensionuser_user {
    service_user = true
  }
}

# Group carrying the CI permissions
resource "oci_identity_domains_group" "github_actions" {
  count = local.oidc_enabled

  idcs_endpoint = data.oci_identity_domain.main[0].url
  schemas       = ["urn:ietf:params:scim:schemas:core:2.0:Group"]

  display_name = "${local.name_prefix}-github-actions"

  members {
    type  = "User"
    value = oci_identity_domains_user.github_actions[0].id
  }
}

# Confidential OAuth client authorized to call the token exchange endpoint
resource "oci_identity_domains_app" "github_token_exchange" {
  count = local.oidc_enabled

  idcs_endpoint = data.oci_identity_domain.main[0].url
  schemas       = ["urn:ietf:params:scim:schemas:oracle:idcs:App"]

  display_name = "${local.name_prefix}-github-token-exchange"
  active       = true

  based_on_template {
    value = "CustomWebAppTemplateId"
  }

  client_type     = "confidential"
  is_oauth_client = true
  allowed_grants  = ["client_credentials", "urn:ietf:params:oauth:grant-type:token-exchange"]
}

# Trust GitHub Actions tokens for pushes to main
# (the workflow exchanges its OIDC JWT at <domain>/oauth2/v1/token, e.g. via
# gtrevorrow/oci-token-exchange-action, then calls OCI with the UPST)
resource "oci_identity_domains_identity_propagation_trust" "github" {
  count = local.oidc_enabled

  idcs_endpoint = data.oci_identity_domain.main[0].url
  schemas       = ["urn:ietf:params:scim:schemas:oracle:idcs:IdentityPropagationTrust"]

  name   = "${local.name_prefix}-github-actions"
  type   = "JWT"
  active = true

  issuer              = "https://token.actions.githubusercontent.com"
  public_key_endpoint = "https://token.actions.githubusercontent.com/.well-known/jwks"

  subject_claim_name = "sub"
  subject_type       = "User"

  allow_impersonation = true

  oauth_clients = [oci_identity_domains_app.github_token_exchange[0].name]

  impersonation_service_users {
    rule  = "sub eq \"repo:${var.github_repository}:ref:refs/heads/main\""
    value = oci_identity_domains_user.github_actions[0].id
  }
}

# Deploy permissions (mirrors aws github_actions role policy: push images,
# roll container instances)
resource "oci_identity_policy" "github_actions" {
  count = local.oidc_enabled

  compartment_id = oci_identity_compartment.main.id
  name           = "${local.name_prefix}-github-actions"
  description    = "GitHub Actions deploy permissions for ${local.name_prefix}"

  # NOTE: plain group names resolve in the default identity domain; for a
  # non-default domain prefix with '<domain-name>'/'<group-name>'.
  statements = [
    "Allow group ${oci_identity_domains_group.github_actions[0].display_name} to manage repos in compartment ${oci_identity_compartment.main.name}",
    "Allow group ${oci_identity_domains_group.github_actions[0].display_name} to manage compute-container-instances in compartment ${oci_identity_compartment.main.name}",
    "Allow group ${oci_identity_domains_group.github_actions[0].display_name} to use virtual-network-family in compartment ${oci_identity_compartment.main.name}",
    "Allow group ${oci_identity_domains_group.github_actions[0].display_name} to use load-balancers in compartment ${oci_identity_compartment.main.name}",
  ]

  freeform_tags = local.common_tags
}
