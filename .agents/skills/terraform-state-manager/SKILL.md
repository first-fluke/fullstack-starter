---
name: terraform-state-manager
description: Manages Terraform state operations such as importing, moving, and removing resources. Use this skill when the user needs to refactor Terraform state, import existing infrastructure, fixing state drift, or migrate backends without destroying resources.
---

# Terraform State Manager

This skill guides you through safe Terraform state manipulation operations.

## When to Use

- Importing existing cloud resources into Terraform management (`terraform import`)
- Renaming resources or moving them into/out of modules (`terraform state mv`)
- Removing resources from Terraform control without destroying them (`terraform state rm`)
- Migrating state between backends (e.g., local to GCS/S3)
- Fixing state locks or corruption

## Critical Safety Rules

> [!IMPORTANT]
> **ALWAYS** follow these rules to prevent data loss or service downtime.

1.  **Backup First**: Create a backup of your state file (`.tfstate`) before ANY operation.
    ```bash
    terraform state pull > backup.tfstate
    ```
2.  **Plan After**: Run `terraform plan` immediately after any state change to verify the result is a "no-op" (no changes detected) or matches expectation.
3.  **One by One**: Perform operations incrementally rather than in bulk.
4.  **Communicate**: Ensure no one else is running Terraform during maintenance.

## Common Operations

### 1. Importing Resources

Use when you have a resource in the cloud but not in Terraform state.

1.  **Write Config**: Create the `resource` block in your `.tf` files.
2.  **Import**:
    ```bash
    terraform import <resource_address> <cloud_id>
    # Example: terraform import google_storage_bucket.my_bucket my-project-bucket-name
    ```
3.  **Verify**: Run `terraform plan`. It should be empty or show only minor metadata updates.

### 2. Moving Resources (Refactoring)

Use when renaming resources or moving them into modules.

```bash
terraform state mv <source_address> <destination_address>
# Example: terraform state mv google_storage_bucket.old_name module.storage.google_storage_bucket.new_name
```

### 3. Removing Resources

Use when you want to stop managing a resource with Terraform but keep it running.

```bash
terraform state rm <resource_address>
```

### 4. Migrating Backend

Use to change where state is stored.

1.  **Update Config**: Change the `backend` block in `versions.tf` or `backend.tf`.
2.  **Migrate**:
    ```bash
    terraform init -migrate-state
    ```
    Answer "yes" to copy the state to the new location.

## Troubleshooting

- **State Lock**: If a process crashed and left a lock:
    ```bash
    terraform force-unlock <LOCK_ID>
    ```
    *Warning: Be absolutely sure no other process is running.*
