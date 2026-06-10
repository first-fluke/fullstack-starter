# OCI Infrastructure

Terraform configuration for deploying the fullstack-starter stack to Oracle Cloud Infrastructure. See [`../README.md`](../README.md) for the cross-cloud stack comparison.

## Architecture

| Component | OCI Service |
|-----------|-------------|
| Isolation boundary | Child compartment under `parent_compartment_ocid` |
| API / Web / Worker | Container Instances (fixed counts, no autoscaling) |
| Container registry | OCIR (`oci_artifacts_container_repository`) |
| Load balancing | Flexible LB + routing policies (host/path) |
| Database | OCI Database with PostgreSQL 16 |
| Cache | OCI Cache (Redis 7, TLS-only) |
| Queues | OCI Queue ×3 (built-in DLQ, delivery count 5) |
| Scheduled jobs | — (documented gap, `schedules` is a no-op) |
| Uploads storage | Object Storage `uploads` bucket |
| Static assets / CDN | Object Storage `static` bucket (no first-party CDN) |
| WAF | WAF policy on LB (rate limit ~1000 req/min/IP) |
| CI/CD auth | Identity propagation trust (GitHub OIDC → UPST) |
| Runtime auth | Dynamic group + resource principal |
| Monitoring | ONS topic + Monitoring alarms (LB 5xx, PG CPU) |

## Prerequisites

- Terraform >= 1.12.0 (the native `backend "oci"` requires it — newer than the >= 1.9.0 floor of the other stacks)
- OCI credentials with admin access in the parent compartment plus identity-domain administration for the OIDC trust (`~/.oci/config` or explicit `user_ocid`/`fingerprint`/`private_key_path` vars)
- An Object Storage bucket for remote state (see `versions.tf`)
- An OCI Certificates service certificate in the same region when using a custom domain (`certificate_ocid`)

## Usage

```bash
cd apps/infra/oci

# Initialize with your state backend (native OCI backend, Terraform >= 1.12)
terraform init \
  -backend-config="bucket=your-tfstate-bucket" \
  -backend-config="namespace=your-objectstorage-namespace" \
  -backend-config="key=oci/terraform.tfstate" \
  -backend-config="region=ap-seoul-1" \
  -backend-config="config_file_profile=DEFAULT"

# Copy and edit variables
cp terraform.tfvars.example terraform.tfvars

# Plan / apply (secrets injected via Infisical)
mise //apps/infra/oci:plan
mise //apps/infra/oci:apply

# Production
cp terraform.prod.tfvars.example terraform.prod.tfvars
mise //apps/infra/oci:plan:prod
mise //apps/infra/oci:apply:prod
```

## Secrets

All sensitive variables (`DATABASE_PASSWORD`, `JWT_SECRET`, `BETTER_AUTH_SECRET`, OAuth keys, AI API keys) are injected as `TF_VAR_*` environment variables via `infisical run`, same as the GCP/AWS/Azure setups — Infisical is the single source of truth. The DB password is set as the PostgreSQL admin password and wired into the container instance environments.

## CI/CD (GitHub Actions OIDC)

OCI supports keyless OIDC federation via identity-domain **identity propagation trust** (GA since 2025): the GitHub Actions JWT is exchanged for a short-lived User Principal Session Token (UPST) impersonating a non-interactive service user. Set `identity_domain_ocid` (usually the Default domain OCID) and Terraform provisions the service user, group, deploy policy, confidential token-exchange client, and the trust pinned to `repo:<github_repository>:ref:refs/heads/main`.

<!-- oma-docs:ignore-start -->
In the workflow, exchange the GitHub OIDC token at the `github_actions_token_endpoint` output using the `github_actions_client_id` output (e.g. with `gtrevorrow/oci-token-exchange-action`), then use the UPST for `oci` CLI / OCIR docker login (`BEARER_TOKEN` username).
<!-- oma-docs:ignore-end -->

If `identity_domain_ocid` is empty no CI identity is provisioned — fall back to a dedicated IAM user with an API key stored as GitHub secrets (deviation from the repo's "OIDC first" rule, only for tenancies where you lack identity-domain admin rights).

## Routing

<!-- oma-docs:ignore-start -->
- With `domain` + `certificate_ocid`: HTTPS listener forwards to Web by default; a routing policy sends `api.<domain>` to API; the HTTP listener 301-redirects to HTTPS via a rule set.
- Without a certificate: a single HTTP listener forwards to Web, with `/api/v1*`, `/health`, `/docs`, `/openapi.json` routed to API by a routing policy.
<!-- oma-docs:ignore-end -->

## Notes

Honest gaps versus the other stacks, found while verifying against 2026 docs:

- **No autoscaling**: OCI Container Instances have no scaling rules, no rolling deploys, and no image-drift updates. Capacity is `api_count` / `web_count` / `worker_count` (fixed). Deploys restart or recreate instances so `:latest` is re-pulled. If you outgrow this, the OCI-native answer is OKE (Kubernetes), not Container Instances.
- **No first-party CDN**: OCI has no CloudFront/Cloud CDN/Front Door equivalent. The `static` bucket ships private — serve via pre-authenticated requests (see `storage.tf`) or put a third-party CDN (e.g. Cloudflare) in front.
- **No cron→queue scheduler**: Resource Scheduler only does start/stop lifecycle actions and parameterless Functions triggers; there is no EventBridge/Cloud Scheduler equivalent that publishes a payload to a queue. The `schedules` variable is a validated no-op; `scheduler.tf` documents two workarounds.
- **State backend**: Oracle deprecated the S3-compatible Object Storage backend; this stack uses the native `backend "oci"` (Terraform >= 1.12), which is why the `required_version` floor is higher than the other stacks.
- **OIDC**: supported (see CI/CD above) but needs identity-domain admin rights and a one-time `identity_domain_ocid` input; policy statements reference plain group names, which resolve in the **Default** identity domain — prefix `'<domain>'/'<group>'` in `iam.tf` if you use a non-default domain.
- **Database name**: `oci_psql_db_system` has no database-name argument — create the `app` database once after provisioning (or via migrations); see the comment in `postgres.tf`. Read scaling guidance also lives there.
- **Runtime identity**: container instances authenticate to Queue/Object Storage/OCIR through a dynamic group + resource principal (`iam.tf`) — no static keys in the containers beyond app-level secrets.
- **OCIR**: repositories are created explicitly so they land in the stack compartment with tags (implicit creation on push would put them in the tenancy root). Image retention (ECR "keep last 10" equivalent) is a console/CLI-level OCIR policy, not Terraform.
- **OCI Cache is TLS-only** — clients must connect with TLS (`REDIS_TLS=true`).
- **Free tier**: OCI's Always Free tier covers the 10 Mbps flexible LB and (separately) generous A1 Arm compute for plain VMs; Container Instances, PostgreSQL, and OCI Cache are paid. Dev defaults are sized minimal; `CI.Standard.A1.Flex` halves container cost if you build arm64 images.
- **Logs**: Container Instances expose container logs via the API/console only; there is no managed log-export integration like CloudWatch Logs to wire up in Terraform yet.
