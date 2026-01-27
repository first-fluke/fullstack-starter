# GCP Project Migration Guide

This document outlines the entire process of migrating a GCP project to a new project.

## Migration Checklist

### Phase 1: Preparation
- [ ] Create new GCP Project
- [ ] Enable specific APIs (see list below)
- [ ] Configure infrastructure with Terraform (`terraform apply`)
- [ ] Create Cloud SQL instance and DB

### Phase 2: Data Migration
- [ ] Cloud SQL database dump and restore
- [ ] GCS bucket data copy (prod, backup)
- [ ] Container image migration (api, web)

### Phase 3: Configuration Changes
- [ ] Update GitHub Secrets
- [ ] Change source code configuration (`config.py`, etc.)
- [ ] Change Terraform environment variables

### Phase 4: Deployment and Verification
- [ ] Terraform apply
- [ ] GitHub Actions deployment test
- [ ] API/Web endpoint testing

---

## Required API List

APIs to enable in the new project:

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

---

## Database Migration

### Cloud SQL Export (Old Project)

```bash
# Grant bucket permissions to old project's Cloud SQL service account
OLD_SA=$(gcloud sql instances describe OLD_INSTANCE \
  --project=OLD_PROJECT --format="value(serviceAccountEmailAddress)")

gcloud storage buckets add-iam-policy-binding gs://MIGRATION_BUCKET \
  --member="serviceAccount:$OLD_SA" \
  --role="roles/storage.objectAdmin"

# Create DB Dump
gcloud sql export sql OLD_INSTANCE gs://MIGRATION_BUCKET/dump.sql \
  --database=your-db-name \
  --project=OLD_PROJECT
```

### Cloud SQL Import (New Project)

```bash
# Grant bucket permissions to new project's Cloud SQL service account
NEW_SA=$(gcloud sql instances describe NEW_INSTANCE \
  --project=NEW_PROJECT --format="value(serviceAccountEmailAddress)")

gcloud storage buckets add-iam-policy-binding gs://MIGRATION_BUCKET \
  --member="serviceAccount:$NEW_SA" \
  --role="roles/storage.objectViewer"

# DB Import
gcloud sql import sql NEW_INSTANCE gs://MIGRATION_BUCKET/dump.sql \
  --database=your-db-name \
  --user=postgres \
  --project=NEW_PROJECT
```

### Direct Import (using psql)

For Private IP instances, either temporarily enable Public IP or use Cloud SQL Proxy:

```bash
# Enable Public IP
gcloud sql instances patch NEW_INSTANCE --assign-ip --project=NEW_PROJECT

# Authorize IP
MY_IP=$(curl -s ifconfig.me)
gcloud sql instances patch NEW_INSTANCE \
  --authorized-networks=$MY_IP \
  --project=NEW_PROJECT

# Import directly with psql
PGPASSWORD='PASSWORD' psql -h PUBLIC_IP -U your-db-user -d your-db-name -f dump.sql
```

---

## GCS Bucket Migration

```bash
# Grant read permission to new account on existing bucket (using old account)
gcloud storage buckets add-iam-policy-binding gs://OLD_BUCKET \
  --member="user:NEW_ACCOUNT@gmail.com" \
  --role="roles/storage.objectViewer"

# Create new bucket and sync (using new account)
gcloud storage buckets create gs://NEW_BUCKET --location=REGION --project=NEW_PROJECT
gcloud storage rsync -r gs://OLD_BUCKET gs://NEW_BUCKET
```

### Required Bucket List
| Old Bucket       | New Bucket          |
| ---------------- | ------------------- |
| `PROJECT-prod`   | `PROJECT-v2-prod`   |
| `PROJECT-backup` | `PROJECT-v2-backup` |

---

## Container Image Migration

```bash
# Configure Docker Authentication
gcloud auth configure-docker OLD_REGION-docker.pkg.dev,NEW_REGION-docker.pkg.dev

# Image Pull -> Tag -> Push
docker pull OLD_REGION-docker.pkg.dev/OLD_PROJECT/REPO/IMAGE:TAG
docker tag OLD_REGION-docker.pkg.dev/OLD_PROJECT/REPO/IMAGE:TAG \
  NEW_REGION-docker.pkg.dev/NEW_PROJECT/REPO/IMAGE:TAG
docker push NEW_REGION-docker.pkg.dev/NEW_PROJECT/REPO/IMAGE:TAG
```

---

## Update GitHub Secrets

Update in Repository Settings > Secrets and variables > Actions:

| Secret                           | Format                                                                                         |
| -------------------------------- | ---------------------------------------------------------------------------------------------- |
| `GCP_WORKLOAD_IDENTITY_PROVIDER` | `projects/PROJECT_NUMBER/locations/global/workloadIdentityPools/POOL_ID/providers/PROVIDER_ID` |
| `GCP_SERVICE_ACCOUNT`            | `SERVICE_ACCOUNT@PROJECT_ID.iam.gserviceaccount.com`                                           |

### How to Retrieve Values

```bash
# Project Number
gcloud projects describe NEW_PROJECT --format="value(projectNumber)"

# WIF Provider Full Path
gcloud iam workload-identity-pools providers describe PROVIDER_ID \
  --workload-identity-pool=POOL_ID \
  --location=global \
  --project=NEW_PROJECT \
  --format="value(name)"
```

---

## Source Code Changes

### `apps/api/src/lib/config.py`
```python
gcs_bucket_name: str = "NEW_BUCKET_NAME"
```

### `apps/infra/compute-*.tf`
```hcl
env {
  name  = "GCS_BUCKET_NAME"
  value = "NEW_BUCKET_NAME"
}
```

---

## Automation Script

To automate the entire migration:

```bash
./.agent/skills/gcp-migration/scripts/migrate-gcp-project.sh \
  --old-project OLD_PROJECT \
  --new-project NEW_PROJECT \
  --old-region OLD_REGION \
  --new-region NEW_REGION
```

---

## Notes

1. **Cloud SQL Private IP**: Cannot be accessed directly from local. Temporary Public IP enablement required.
2. **Account Switching**: `gcloud config set account` is mandatory when working across old/new projects.
3. **Permission Propagation Delay**: May require waiting a few minutes after IAM changes.
4. **Terraform lifecycle.ignore_changes**: Image changes should be performed separately via `gcloud run deploy`.

---

## Terraform Variable Structure

Terraform files have parameterized project ID and region, so you only need to modify the top of `variables.tf` during migration.

### Key Variables (Top of `variables.tf`)

```hcl
variable "project_id" {
  description = "GCP Project ID"
  type        = string
  default     = "your-project-id"  # ← Change to new project ID
}

variable "region" {
  description = "GCP Region"
  type        = string
  default     = "your-region"  # ← Change if necessary
}
```

### Parameterized Resource List

| File           | Parameterized Items                             |
| -------------- | ----------------------------------------------- |
| `provider.tf`  | `project`, `region`                             |
| `storage.tf`   | Bucket name (`${var.project_id}-prod`), Region  |
| `database.tf`  | `project`, `region`, VPC path                   |
| `iam.tf`       | `project`, SA email                             |
| `compute-*.tf` | Image path, `GOOGLE_CLOUD_PROJECT_ID` env var   |

### Items Requiring Manual Changes

The following items cannot be parameterized due to Terraform limitations and require manual changes:

1. **`provider.tf` - backend bucket**
   ```hcl
   backend "gcs" {
     bucket = "NEW_PROJECT-tfstate"  # Manual change
   }
   ```

2. **`database.tf` - Instance Name** (Keep effectively same if retaining old instance, change if creating new)
   ```hcl
   name = "your-instance-name"
   ```
