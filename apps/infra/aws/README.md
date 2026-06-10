# AWS Infrastructure

Terraform configuration for deploying the fullstack-starter stack to AWS. This is the AWS counterpart of the GCP configuration in [`../gcp/`](../gcp/) (ported from [first-fluke/agogeo](https://github.com/first-fluke/agogeo)).

## Architecture

| Component | AWS Service | GCP Equivalent (`../gcp/`) |
|-----------|-------------|----------------------------|
| API / Web / Worker | ECS Fargate | Cloud Run |
| Container registry | ECR | Artifact Registry |
| Load balancing | ALB (host/path routing) | Global LB + Cloud Run |
| Database | Aurora PostgreSQL 16 | Cloud SQL |
| Cache | ElastiCache Redis 7 | Memorystore |
| Queues | SQS (default / high-priority / low-priority + DLQ) | Cloud Tasks |
| Events | SNS tasks topic → SQS fan-out | Pub/Sub |
| Scheduled jobs | EventBridge Scheduler → SNS (`schedules` var) | Cloud Scheduler → Pub/Sub |
| Uploads storage | S3 | GCS |
| Static assets / CDN | S3 + CloudFront (OAC) | GCS + Cloud CDN |
| WAF | WAFv2 on ALB (rate limit + managed rules) | Cloud Armor |
| Email | SES (optional, `ses_domain`) | — |
| CI/CD auth | GitHub Actions OIDC role | Workload Identity Federation |
| Monitoring | CloudWatch dashboard + alarms + SNS | — |

## Prerequisites

- Terraform >= 1.9.0
- AWS credentials with admin access (initial provisioning)
- An S3 bucket + DynamoDB table for remote state (see `versions.tf`)
- ACM certificate in the same region when using a custom domain

## Usage

```bash
cd apps/infra/aws

# Initialize with your state backend
terraform init \
  -backend-config="bucket=your-tfstate-bucket" \
  -backend-config="key=aws/terraform.tfstate" \
  -backend-config="region=ap-northeast-2" \
  -backend-config="dynamodb_table=your-tflock-table" \
  -backend-config="encrypt=true"

# Copy and edit variables
cp terraform.tfvars.example terraform.tfvars

# Plan / apply (secrets injected via Infisical)
mise //apps/infra/aws:plan
mise //apps/infra/aws:apply

# Production
cp terraform.prod.tfvars.example terraform.prod.tfvars
mise //apps/infra/aws:plan:prod
mise //apps/infra/aws:apply:prod
```

## Secrets

All sensitive variables (`DATABASE_PASSWORD`, `JWT_SECRET`, `BETTER_AUTH_SECRET`, OAuth keys, AI API keys) are injected as `TF_VAR_*` environment variables via `infisical run`, same as the GCP setup — Infisical is the single source of truth. The DB password is set as the Aurora master password and wired into ECS task environments.

## Routing

<!-- oma-docs:ignore-start -->
- With `domain` + `acm_certificate_arn`: HTTPS listener forwards to Web by default; `api.<domain>` forwards to API; HTTP redirects to HTTPS.
- Without a certificate: a single HTTP listener forwards to Web, with `/api/v1/*`, `/health`, `/docs`, `/openapi.json` routed to API.
<!-- oma-docs:ignore-end -->

## Notes

- Single NAT gateway (cost-optimized) — all private subnets share one NAT.
- ECS services ignore `task_definition` / `desired_count` drift so CI/CD deployments (new task definition revisions) are not reverted by Terraform.
- ElastiCache has transit encryption enabled — clients must connect with TLS (`REDIS_TLS=true`).
- SES is opt-in: set `ses_domain` and publish the `ses_verification_token` (TXT) and `ses_dkim_tokens` (CNAME) outputs to DNS.
