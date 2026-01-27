---
name: GCP Project Migration
description: Migration between GCP Projects (DB, Storage, Container Images, Terraform)
---

# GCP Project Migration Skill

This skill guides you through the process of fully migrating from one GCP project to another.

## Prerequisites

1. Owner/Editor permissions for **both GCP projects**
2. **gcloud CLI** installed and authenticated
3. **Docker** installed (for container image migration)
4. **Terraform infrastructure must be deployed** to the new project first

## Migration Steps

### Phase 1: Enable APIs

Enable required APIs in the new project:

```bash
gcloud services enable \
  sqladmin.googleapis.com \
  run.googleapis.com \
  artifactregistry.googleapis.com \
  iamcredentials.googleapis.com \
  cloudtasks.googleapis.com \
  pubsub.googleapis.com \
  storage.googleapis.com \
  compute.googleapis.com \
  vpcaccess.googleapis.com \
  aiplatform.googleapis.com \
  --project=NEW_PROJECT_ID
```

### Phase 2: Database Migration

1. **Export from old project**
   ```bash
   # Switch to old project account
   gcloud config set account OLD_ACCOUNT@gmail.com
   
   # Grant bucket permissions to Cloud SQL service account
   OLD_SA=$(gcloud sql instances describe OLD_INSTANCE --project=OLD_PROJECT --format="value(serviceAccountEmailAddress)")
   gcloud storage buckets add-iam-policy-binding gs://MIGRATION_BUCKET \
     --member="serviceAccount:$OLD_SA" \
     --role="roles/storage.objectAdmin"
   
   # Dump DB
   gcloud sql export sql OLD_INSTANCE gs://MIGRATION_BUCKET/dump.sql \
     --database=database_name --project=OLD_PROJECT
   ```

2. **Import to new project**
   ```bash
   # Switch to new project account
   gcloud config set account NEW_ACCOUNT@gmail.com
   
   # Grant permissions and Import
   NEW_SA=$(gcloud sql instances describe NEW_INSTANCE --project=NEW_PROJECT --format="value(serviceAccountEmailAddress)")
   gcloud storage buckets add-iam-policy-binding gs://MIGRATION_BUCKET \
     --member="serviceAccount:$NEW_SA" \
     --role="roles/storage.objectViewer"
   
   gcloud sql import sql NEW_INSTANCE gs://MIGRATION_BUCKET/dump.sql \
     --database=database_name --user=db_username --project=NEW_PROJECT
   ```

### Phase 3: GCS Bucket Migration

```bash
# Grant read permission to new account from old account
gcloud storage buckets add-iam-policy-binding gs://OLD_BUCKET \
  --member="user:NEW_ACCOUNT@gmail.com" \
  --role="roles/storage.objectViewer"

# Create and sync bucket in new account
gcloud storage buckets create gs://NEW_BUCKET --location=REGION --project=NEW_PROJECT
gcloud storage rsync -r gs://OLD_BUCKET gs://NEW_BUCKET
```

### Phase 4: Container Image Migration

```bash
# Docker Authentication
gcloud auth configure-docker OLD_REGION-docker.pkg.dev,NEW_REGION-docker.pkg.dev

# Image Pull -> Tag -> Push
docker pull OLD_REGION-docker.pkg.dev/OLD_PROJECT/REPO/IMAGE:TAG
docker tag OLD_REGION-docker.pkg.dev/OLD_PROJECT/REPO/IMAGE:TAG \
  NEW_REGION-docker.pkg.dev/NEW_PROJECT/REPO/IMAGE:TAG
docker push NEW_REGION-docker.pkg.dev/NEW_PROJECT/REPO/IMAGE:TAG
```

### Phase 5: Modify Terraform Variables

Modify only the variables at the top of the `apps/infra/variables.tf` file:

```hcl
variable "project_id" {
  default = "NEW_PROJECT_ID"  # ← Change
}

variable "region" {
  default = "your_region"  # ← Change if necessary
}
```

**Manual Changes Required**:
- `backend.bucket` in `provider.tf` (Terraform limitation)

### Phase 6: Update GitHub Secrets

In Repository Settings > Secrets and variables > Actions:

| Secret                           | Value                                                                                                    |
| -------------------------------- | -------------------------------------------------------------------------------------------------------- |
| `GCP_WORKLOAD_IDENTITY_PROVIDER` | `projects/PROJECT_NUMBER/locations/global/workloadIdentityPools/your-pool/providers/github-provider` |
| `GCP_SERVICE_ACCOUNT`            | `your-deployer@NEW_PROJECT.iam.gserviceaccount.com`                                                  |

Retrieve Values:
```bash
# Project Number
gcloud projects describe NEW_PROJECT --format="value(projectNumber)"

# WIF Provider
gcloud iam workload-identity-pools providers describe github-provider \
  --workload-identity-pool=your-pool --location=global --project=NEW_PROJECT --format="value(name)"
```

### Phase 7: Code Changes and Deployment

1. Change `gcs_bucket_name` default value in `apps/api/src/lib/config.py`
2. Commit and Push
3. GitHub Actions will auto-deploy

## Automation Script

Run full data migration at once:

```bash
./.agent/skills/gcp-migration/scripts/migrate-gcp-project.sh \
  --old-project OLD_PROJECT_ID \
  --new-project NEW_PROJECT_ID \
  --old-region your_old_region \
  --new-region your_new_region
```

## References

- [Migration Guide](references/gcp-migration-guide.md)
- [Migration Script](scripts/migrate-gcp-project.sh)

## Troubleshooting

### Cloud Run Job fails with TCP Connection Error

**Symptoms**:
```
Is the server running on that host and accepting TCP/IP connections?
```

**Cause**: A VPC Connector is required for Cloud Run Jobs to access Cloud SQL Private IP.

**Resolution**:
```bash
# 1. Enable VPC Access API
gcloud services enable vpcaccess.googleapis.com --project=NEW_PROJECT_ID

# 2. Check VPC Connector
gcloud compute networks vpc-access connectors list \
  --region=REGION \
  --project=NEW_PROJECT_ID

# 3. Create VPC Connector (if missing, use same network as Cloud SQL)
gcloud compute networks vpc-access connectors create CONNECTOR_NAME \
  --region=REGION \
  --network=NETWORK_NAME \
  --range=10.9.0.0/28 \
  --project=NEW_PROJECT_ID

# 4. Attach VPC Connector to Cloud Run Job
gcloud run jobs update JOB_NAME \
  --region=REGION \
  --project=NEW_PROJECT_ID \
  --vpc-connector=CONNECTOR_NAME \
  --vpc-egress=private-ranges-only
```

### Direct VPC and VPC Connector Conflict

**Symptoms**:
```
VPC connector and direct VPC can not be used together
```

**Resolution**: Remove Direct VPC first, then add VPC Connector:
```bash
# Remove Direct VPC
gcloud run jobs update JOB_NAME \
  --region=REGION \
  --project=NEW_PROJECT_ID \
  --clear-network

# Add VPC Connector
gcloud run jobs update JOB_NAME \
  --region=REGION \
  --project=NEW_PROJECT_ID \
  --vpc-connector=CONNECTOR_NAME \
  --vpc-egress=private-ranges-only
```

### Password Authentication Failed

**Symptoms**:
```
FATAL: password authentication failed for user "username"
```

**Resolution**:
```bash
# Check Cloud SQL user list
gcloud sql users list \
  --instance=INSTANCE_NAME \
  --project=NEW_PROJECT_ID

# Reset password (if needed)
gcloud sql users set-password USERNAME \
  --instance=INSTANCE_NAME \
  --project=NEW_PROJECT_ID \
  --password="NEW_PASSWORD"
```

### Missing Required Environment Variables

**Symptoms**:
```
pydantic_core._pydantic_core.ValidationError: Field required
jwt_secret_key
```

**Resolution**: Environment variables required for Migration Job:
- `DATABASE_URL` - PostgreSQL connection string
- `JWT_SECRET_KEY` - JWT signing secret

**IMPORTANT**: Use `--update-env-vars` to preserve existing environment variables:
```bash
# WRONG: Overwrites all existing environment variables
gcloud run jobs update JOB_NAME --set-env-vars="KEY=value"

# CORRECT: Adds/Updates while keeping existing environment variables
gcloud run jobs update JOB_NAME --update-env-vars="KEY=value"
```

### Manual Migration Job Fix (Full Steps)

Full process for manually fixing the Migration Job:

```bash
# 1. Enable VPC Access API
gcloud services enable vpcaccess.googleapis.com --project=NEW_PROJECT_ID

# 2. Check Cloud SQL Private IP
DB_IP=$(gcloud sql instances describe INSTANCE_NAME \
  --project=NEW_PROJECT_ID \
  --format="value(ipAddresses[0].ipAddress)")
echo "Cloud SQL Private IP: $DB_IP"

# 3. Create VPC Connector (same network as Cloud SQL)
gcloud compute networks vpc-access connectors create default-connector \
  --region=REGION \
  --network=default \
  --range=10.9.0.0/28 \
  --project=NEW_PROJECT_ID

# 4. Remove Direct VPC (if exists)
gcloud run jobs update JOB_NAME \
  --region=REGION \
  --project=NEW_PROJECT_ID \
  --clear-network

# 5. Connect VPC Connector + Set Env Vars
gcloud run jobs update JOB_NAME \
  --region=REGION \
  --project=NEW_PROJECT_ID \
  --vpc-connector=default-connector \
  --vpc-egress=private-ranges-only \
  --update-env-vars="DATABASE_URL=postgresql+asyncpg://USER:PASS@${DB_IP}:5432/DBNAME,JWT_SECRET_KEY=YOUR_JWT_SECRET"

# 6. Execute Migration
gcloud run jobs execute JOB_NAME \
  --region=REGION \
  --project=NEW_PROJECT_ID

# 7. Check Status
EXECUTION_ID=$(gcloud run jobs executions list \
  --job=JOB_NAME \
  --region=REGION \
  --project=NEW_PROJECT_ID \
  --limit=1 \
  --format="value(name)")

gcloud run jobs executions describe $EXECUTION_ID \
  --region=REGION \
  --project=NEW_PROJECT_ID \
  --format="value(status.conditions[0].status,status.conditions[0].message)"
```

### Verify Cloud Run Job Configuration

```bash
# Check current Job configuration
gcloud run jobs describe JOB_NAME \
  --region=REGION \
  --project=NEW_PROJECT_ID \
  --format="yaml(spec.template.spec.template.spec)"

# Check only VPC configuration
gcloud run jobs describe JOB_NAME \
  --region=REGION \
  --project=NEW_PROJECT_ID \
  --format="yaml(spec.template.metadata.annotations)"

# Check environment variables
gcloud run jobs describe JOB_NAME \
  --region=REGION \
  --project=NEW_PROJECT_ID \
  --format="yaml(spec.template.spec.template.spec.containers[0].env)"
```

## Checklist

- [ ] APIs Enabled
- [ ] Database Migration Completed
- [ ] GCS Bucket Migration Completed
- [ ] Container Image Migration Completed
- [ ] Terraform variables.tf Modified
- [ ] GitHub Secrets Updated
- [ ] config.py Modified and Pushed
- [ ] VPC Connector Created and Attached
- [ ] Migration Job Env Vars Set (DATABASE_URL, JWT_SECRET_KEY)
- [ ] Migration Job Executed Successfully
- [ ] Deployment Verified and Tested
