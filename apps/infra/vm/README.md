# VM Stack (single Compute Engine VM)

One Ubuntu 24.04 VM runs PostgreSQL, Redis, the API, the Web app and the Worker under Docker Compose. Host nginx terminates TLS (Let's Encrypt, HTTP/2 and HTTP/3) and proxies to the containers. Terraform provisions the host; Ansible configures it and deploys image digests. See [`../README.md`](../README.md) for how this compares with the managed stacks.

Pick this stack when fixed monthly cost matters more than autoscaling: a side project, an internal tool, or a small product with a few hundred daily users. Move to `gcp/` when you need more than one instance of anything.

## What Terraform creates

| Resource | Purpose |
|----------|---------|
| VPC + subnet, firewall rules | TCP 80/443 and UDP 443 (QUIC) from the internet; TCP 22 only from the IAP range |
| Static external IP | Point `domain` and `api_domain` A records here |
| `e2-small` VM (Shielded, OS Login, no SSH keys) | Runs Docker Compose; images must be built off-host |
| Dedicated `pd-balanced` data disk + daily snapshots | PostgreSQL, Redis and local backups survive VM recreation (`prevent_destroy`) |
| Service account for the VM | Pulls images, writes backups, reads/writes the uploads bucket, writes logs |
| Backup bucket (versioned, private) | Daily `pg_dump` uploads, expired by lifecycle rule |
| Uploads bucket (private) | API `STORAGE_BACKEND=gcs` |
| Artifact Registry repository | API, Web and Worker images; keeps the newest versions per package |
| Workload Identity pool + CI service account (optional) | Keyless image pushes from GitHub Actions when `github_repository` is set |

## What Ansible configures

- Docker, Compose v2, certbot, unattended-upgrades; the official nginx.org stable package pinned by version, with its signing key fingerprint and HTTP/3 build verified.
- The data disk: formatted only when empty, mounted at `/srv/<app_name>` via fstab, refused if it carries an unexpected filesystem.
- `/opt/<app_name>/compose.yaml`, `/etc/<app_name>/app.env` (0600), the worker schedule file, a systemd unit that brings Compose up on boot.
- Alembic migrations as a one-shot `migrate` service (Compose profile `tools`) before the API starts.
- nginx: HTTP-01 bootstrap → certificate for `domain` + `api_domain` → final HTTPS config with per-IP rate limits, security headers, gzip and fast 404s for scanner paths. A renewal hook reloads nginx after `certbot.timer` renews.
- Daily `pg_dump` to the data disk, uploaded to the backup bucket with the VM's identity; `restore.sh` for the reverse.
- An optional daily maintenance timer (`maintenance_command`).
- A final check that `https://<api_domain>/health` and `https://<domain>/api/health` return 200.

Everything is idempotent. Rerun the playbook to deploy new digests, rotate `app.env`, or change nginx settings.

## Prerequisites

- `mise install` (Terraform, uv). Ansible is not installed system-wide; every `vm:ansible:*` and `vm:deploy*` task runs a pinned `ansible-core` through `uv tool run`.
- `gcloud` authenticated to the project, with the IAP and OS Login APIs enabled (Terraform enables them, but `gcloud compute ssh --tunnel-through-iap` must work for your user).
- Two DNS names you control, for example `www.example.com` (web) and `api.example.com` (API). They share one certificate and must both resolve to the VM before the first deploy, or certificate issuance fails.
- A GCS bucket for Terraform state (`-backend-config="bucket=..."`), as with the other stacks.

## 1. Provision the host

```bash
cp apps/infra/vm/terraform.prod.tfvars.example apps/infra/vm/terraform.prod.tfvars
# set project_id, operator_members (your user:... email), github_repository

mise //apps/infra:vm:init -- -backend-config="bucket=your-tfstate-bucket" -backend-config="prefix=vm/prod"
mise //apps/infra:vm:plan:prod
mise //apps/infra:vm:apply:prod
mise //apps/infra:vm:output
```

Create A records for `domain` and `api_domain` pointing at `public_ip`.

## 2. Build and push images

Images must be `linux/amd64` and are deployed by digest, never by tag. From the repository root:

```bash
REPO=$(cd apps/infra/vm && terraform output -raw artifact_registry_url)
gcloud auth configure-docker "${REPO%%/*}" --quiet

docker buildx build --platform linux/amd64 --push -f apps/api/Dockerfile    -t "$REPO/api:$(git rev-parse --short HEAD)" .
docker buildx build --platform linux/amd64 --push -f apps/worker/Dockerfile -t "$REPO/worker:$(git rev-parse --short HEAD)" .
docker buildx build --platform linux/amd64 --push -f apps/web/Dockerfile \
  --build-arg NEXT_PUBLIC_API_URL=https://api.example.com \
  -t "$REPO/web:$(git rev-parse --short HEAD)" .

# Resolve digests for group_vars
for image in api web worker; do
  gcloud artifacts docker images describe "$REPO/$image:$(git rev-parse --short HEAD)" --format='value(image_summary.fully_qualified_digest)'
done
```

`NEXT_PUBLIC_API_URL` is baked into the Web bundle at build time, so rebuild Web when `api_domain` changes. To push from GitHub Actions instead, set `github_repository` in tfvars and use the `workload_identity_provider` / `github_service_account` outputs in the existing `deploy-*.yml` workflows, replacing their Cloud Run step with the Ansible deploy below.

## 3. Configure Ansible

```bash
cd apps/infra/vm/ansible
cp inventory.yml.example inventory.yml                  # instance name, your OS Login username, project, zone
cp group_vars/all/site.yml.example group_vars/all/site.yml
```

`group_vars/all/defaults.yml` holds every tunable with its default (ports, memory limits, rate limits, images, backup schedule). `site.yml` overrides it per deployment and is gitignored. Set at least:

| Variable | Source |
|----------|--------|
| `app_name` | Same value as `app_name` in tfvars |
| `domain`, `api_domain`, `certificate_email` | Your DNS |
| `api_image`, `web_image`, `worker_image` | Digests from step 2 (`...@sha256:...`) |
| `app_env_file` | Absolute path to the runtime env file (below) |
| `backup_bucket`, `data_device` | `terraform output` |

### Runtime secrets (`app.env`)

The API and Worker read `/etc/<app_name>/app.env`. Compose also interpolates `POSTGRES_*` from it. Required keys:

```dotenv
POSTGRES_DB=app
POSTGRES_USER=app
POSTGRES_PASSWORD=<url-safe random>          # letters, digits, _ and - only: it is embedded in DATABASE_URL
JWT_SECRET=<random>
JWE_SECRET_KEY=<random>
STORAGE_BACKEND=gcs
GCS_BUCKET_NAME=<terraform output uploads_bucket>
```

Add OAuth client ids and secrets, AI keys and anything else from [`apps/api/.env.example`](../../api/.env.example). Do not set `DATABASE_URL`, `CORS_ORIGINS`, `API_PUBLIC_URL`, `WEBAUTHN_*` or `TRUSTED_PROXY_IPS`: Compose derives them from `domain` and `api_domain`. With Infisical, `mise //apps/infra:vm:env:export` writes the `/vm` path of the `prod` environment to `ansible/app.env` (gitignored); point `app_env_file` at it.

## 4. Deploy

```bash
mise //apps/infra:vm:check     # terraform fmt + ansible syntax
mise //apps/infra:vm:deploy
```

The first run installs packages, formats the disk, obtains the certificate and starts the containers. Later runs with new digests pull and recreate only the changed services. Each deploy ends with public health checks over TLS.

Day two:

```bash
mise //apps/infra:vm:deploy:schedules          # changed apps/worker/schedules.toml only
gcloud compute ssh <instance> --tunnel-through-iap --zone <zone>
sudo docker compose --env-file /etc/<app_name>/app.env -f /opt/<app_name>/compose.yaml logs --tail=100 api
sudo /opt/<app_name>/backup.sh                 # ad-hoc backup
sudo /opt/<app_name>/restore.sh /srv/<app_name>/backups/<stamp>/database.dump
```

## Worker scheduling

There is no Cloud Scheduler here, so the worker runs an in-process APScheduler when `WORKER_SCHEDULES_FILE` is set (Compose sets it). Jobs live in [`apps/worker/schedules.toml`](../../worker/schedules.toml) and reference handlers registered in `apps/worker/src/jobs`. Validate locally with `mise //apps/worker:schedules:check`. The worker runs as exactly one container; the scheduler has no distributed lock, so do not scale it out on this stack.

## Operational notes

- **Memory.** `e2-small` has 2 GB. Compose caps postgres 512m, api 512m, web 512m, worker 256m, redis 128m (`*_mem_limit` in defaults). Move to `e2-medium` before raising them.
- **Rate limits.** nginx applies 20 r/s per IP overall, 60 r/s for `/_next/static/`, and exact-path limits on `/api/auth/login|register|refresh` (`rate_limited_locations`). The API also rate-limits auth routes itself; nginx is the cheaper first line.
- **Recreating the VM.** `terraform taint`/replace the instance; the data disk and buckets are `prevent_destroy`. Rerun the playbook, which reattaches the existing ext4 disk and reissues nothing (certificates live on the boot disk and will be reissued once).
- **Previews.** `preview_mode: true` adds `X-Robots-Tag: noindex` on the web host. The API host always sends it.
- **Cost.** Roughly one `e2-small`, one 30 GB disk plus snapshots, one static IP, bucket storage and egress. No load balancer, no NAT, no managed database.
