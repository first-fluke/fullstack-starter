# Azure Infrastructure

Terraform configuration for deploying the fullstack-starter stack to Azure. See [`../README.md`](../README.md) for the cross-cloud stack comparison.

## Architecture

| Component | Azure Service |
|-----------|---------------|
| API / Web / Worker | Container Apps (one environment, three apps) |
| Container registry | Azure Container Registry (shared, api/web/worker repos) |
| Ingress / routing | Container Apps built-in ingress (api:8000, web:3000 external; worker internal) |
| Database | PostgreSQL Flexible Server 16 (private, delegated subnet + private DNS) |
| Cache | Azure Cache for Redis (TLS only) |
| Queues + events | Service Bus topic `tasks` + priority-filtered subscriptions (built-in DLQ) |
| Scheduled jobs | Container Apps Jobs cron (`schedules` var) |
| Uploads storage | Storage account `uploads` container |
| Static assets / CDN | `static` container + Front Door Standard |
| WAF | Front Door WAF policy (rate-limit custom rule) |
| CI/CD auth | Entra ID app + federated credential (GitHub OIDC) |
| Monitoring | Log Analytics + action group + metric alerts |

## Prerequisites

- Terraform >= 1.9.0
- Azure CLI logged in with Owner/Contributor on the target subscription, plus permission to create Entra ID applications (initial provisioning)
- A resource group + storage account + blob container for remote state (see `versions.tf`)
- Registered resource providers: `Microsoft.App`, `Microsoft.ContainerRegistry`, `Microsoft.DBforPostgreSQL`, `Microsoft.Cache`, `Microsoft.ServiceBus`, `Microsoft.Cdn`, `Microsoft.Storage`, `Microsoft.OperationalInsights`, `Microsoft.Insights` (`az provider register --namespace <name>`)
- `ARM_SUBSCRIPTION_ID` exported (azurerm 4.x requires an explicit subscription)

## Usage

```bash
cd apps/infra/az

# Initialize with your state backend
terraform init \
  -backend-config="resource_group_name=your-tfstate-rg" \
  -backend-config="storage_account_name=yourtfstateaccount" \
  -backend-config="container_name=tfstate" \
  -backend-config="key=az/terraform.tfstate"

# Copy and edit variables
cp terraform.tfvars.example terraform.tfvars

# Plan / apply (secrets injected via Infisical)
mise //apps/infra/az:plan
mise //apps/infra/az:apply

# Production
cp terraform.prod.tfvars.example terraform.prod.tfvars
mise //apps/infra/az:plan:prod
mise //apps/infra/az:apply:prod
```

## Secrets

All sensitive variables (`DATABASE_PASSWORD`, `JWT_SECRET`, `BETTER_AUTH_SECRET`, OAuth keys, AI API keys) are injected as `TF_VAR_*` environment variables via `infisical run`, same as the GCP and AWS setups — Infisical is the single source of truth. The DB password is set as the Flexible Server admin password and wired into the apps as a Container Apps secret reference (never a plain env var).

## CI/CD (GitHub Actions OIDC)

<!-- oma-docs:ignore-start -->
Feed the `github_actions_client_id`, `tenant_id`, and `subscription_id` outputs to the `Azure/login@v2` GitHub Action.
<!-- oma-docs:ignore-end --> The service principal has `AcrPush` on the registry and `Contributor` scoped to the stack's resource group only. The federated credential trusts `repo:<github_repository>:ref:refs/heads/main`.

## Notes

- Scheduled jobs belong in the `schedules` variable (Container Apps Jobs with cron triggers running the worker image with `TASK_PAYLOAD`), not in in-worker cron loops — with N worker replicas an in-process cron fires N times, while a job runs exactly once per tick. Job names are capped at 32 characters.
- Container apps ignore `template.container.image` drift so CI/CD deployments (`az containerapp update --image ...`) are not reverted by Terraform.
- WAF: the rate-limit custom rule (~1000 req/min per client IP) works on `Standard_AzureFrontDoor`; managed rule sets (`Microsoft_DefaultRuleSet`, Bot Manager — the XSS/SQLi equivalents) require the Premium SKU. See `waf.tf` for the upgrade snippet.
- Front Door Standard cannot reach a private blob origin (Private Link origins are Premium-only). The `static` container ships private by default — see the note in `cdn.tf` for the two unlock options.
- Redis Basic/Standard tiers have no VNet injection (Premium only); the cache enforces TLS 1.2 (`REDIS_TLS=true`, port 6380) with access key auth injected as a Container Apps secret.
- Read scaling: PostgreSQL Flexible Server supports read replicas via `create_mode = "Replica"` — see the guide comment in `postgres.tf`.
- Worker autoscaling uses the KEDA `azure-servicebus` scaler against the `default` subscription (`worker_queue_depth_target`); the API scales on HTTP concurrency.
- Custom domains for the container apps (`domain` / `api_subdomain`) only switch the URLs the apps advertise — bind the domains + managed certificates on the Container Apps / Front Door side separately.
