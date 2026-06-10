# GCP Infrastructure

Terraform configuration for GCP infrastructure provisioning. See [`../README.md`](../README.md) for the stack overview and the AWS counterpart at [`../aws/`](../aws/).

## Prerequisites

### Enable Required GCP APIs

Before running `terraform apply`, enable the following APIs in your GCP project:

- [Compute Engine API](https://console.cloud.google.com/apis/api/compute.googleapis.com/metrics)
- [Cloud Run API](https://console.cloud.google.com/apis/library/run.googleapis.com)
- [Cloud Tasks API](https://console.cloud.google.com/apis/library/cloudtasks.googleapis.com)
- [IAM Service Account Credentials API](https://console.cloud.google.com/marketplace/product/google/iamcredentials.googleapis.com)
- [Service Networking API](https://console.cloud.google.com/apis/api/servicenetworking.googleapis.com/metrics)

### Domain Configuration

If you use third-party DNS services (Cloudflare, Route53, etc.), you must map your domains at [Cloud Run Domains](https://console.cloud.google.com/run/domains).

## Usage

```bash
# Initialize
mise run init

# Dry-run (dev)
mise run plan

# Apply (dev)
mise run apply

# Dry-run (prod)
mise run plan:prod

# Apply (prod)
mise run apply:prod
```
