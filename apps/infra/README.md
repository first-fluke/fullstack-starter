# Infrastructure

Terraform configurations for provisioning the fullstack-starter stack. Each cloud target lives in its own self-contained root module — pick one (or run several side by side for different environments).

## Stacks

| Directory | Target | Best for |
|-----------|--------|----------|
| [`gcp/`](./gcp/) | GCP — Cloud Run, Cloud SQL, Memorystore, Cloud Tasks, Pub/Sub, GCS, Cloud CDN | Serverless-first, scale-to-zero workloads |
| [`aws/`](./aws/) | AWS — ECS Fargate, Aurora PostgreSQL, ElastiCache, SQS/SNS, S3, CloudFront, SES | Container-first, AWS-native shops |
| [`az/`](./az/) | Azure — Container Apps, PostgreSQL Flexible Server, Azure Cache for Redis, Service Bus, Blob Storage, Front Door | Azure-native shops, KEDA-based scaling |
| [`freemium/`](./freemium/) | Vercel + Supabase + Backblaze B2 | Zero-cost prototypes and side projects |

### Service mapping

| Component | `gcp/` | `aws/` | `az/` |
|-----------|--------|--------|-------|
| API / Web / Worker | Cloud Run | ECS Fargate | Container Apps |
| Container registry | Artifact Registry | ECR | ACR |
| Database (PostgreSQL 16) | Cloud SQL | Aurora | PostgreSQL Flexible Server |
| Cache (Redis 7) | Memorystore | ElastiCache | Azure Cache for Redis |
| Task queues | Cloud Tasks (default / high / low priority) | SQS (default / high-priority / low-priority + DLQ) | Service Bus subscriptions (SQL filter + DLQ) |
| Event bus | Pub/Sub | SNS → SQS fan-out | Service Bus topic fan-out |
| Scheduled jobs | Cloud Scheduler → Pub/Sub (`schedules` var) | EventBridge Scheduler → SNS (`schedules` var) | Container Apps Jobs cron (`schedules` var) |
| Uploads / static assets | GCS + Cloud CDN | S3 + CloudFront (OAC) | Blob Storage + Front Door |
| WAF / rate limiting | Cloud Armor | WAFv2 (rate limit + AWS managed rules) | Front Door WAF (rate limit; managed rules need Premium) |
| Email | — | SES (opt-in via `ses_domain`) | — |
| CI/CD auth | Workload Identity Federation | GitHub Actions OIDC role | Entra ID federated credential |

## Shared conventions

- **Secrets via Infisical.** Every `plan`/`apply` task is wrapped with `infisical run --env=<env> --path=/infra`, which injects secrets as `TF_VAR_*` environment variables (`DATABASE_PASSWORD`, `JWT_SECRET`, `BETTER_AUTH_SECRET`, OAuth and AI keys). Nothing sensitive is committed; `*.tfvars` is gitignored.
- **Remote state.** GCS backend for `gcp/`, S3 + DynamoDB locking for `aws/`, Azure Storage (`azurerm` backend) for `az/`. All are configured at `terraform init` time via `-backend-config`.
- **Naming.** Resources are prefixed with `${app_name}-${environment}` (default `fullstack-starter-dev`).
- **Environment sizing.** `terraform.tfvars` for dev, `terraform.prod.tfvars` for production. Copy from the `.example` files in each stack.
- **API availability.** The API service keeps a minimum of 1 instance/task in every stack (no cold starts).
- **Cron via scheduler services.** Recurring jobs are declared in the `schedules` variable (Cloud Scheduler / EventBridge Scheduler) and flow through the task queue, so each tick runs exactly once regardless of worker count — workers never run in-process cron.

## Usage

All stacks expose the same mise tasks:

```bash
# GCP
mise //apps/infra/gcp:init
mise //apps/infra/gcp:plan
mise //apps/infra/gcp:apply
mise //apps/infra/gcp:plan:prod
mise //apps/infra/gcp:apply:prod

# AWS
mise //apps/infra/aws:init
mise //apps/infra/aws:plan
mise //apps/infra/aws:apply
mise //apps/infra/aws:plan:prod
mise //apps/infra/aws:apply:prod

# Azure
mise //apps/infra/az:init
mise //apps/infra/az:plan
mise //apps/infra/az:apply
mise //apps/infra/az:plan:prod
mise //apps/infra/az:apply:prod

# Formatting / validation (either stack)
mise //apps/infra/gcp:fmt
mise //apps/infra/aws:validate
```

See each stack's README for prerequisites (API enablement, state bucket setup, certificates) and stack-specific notes.
