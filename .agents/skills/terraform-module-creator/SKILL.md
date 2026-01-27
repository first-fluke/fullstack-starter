---
name: terraform-module-creator
description: Helper for scaffolding new Terraform modules. Complements terraform-module-library by providing structure generation.
---

# Terraform Module Creator

This skill assists in scaffolding new Terraform modules following the standards defined in `terraform-module-library`.

## Quick Start

To create a new module, you should create the following directory structure:

```bash
mkdir -p modules/<module-name>
touch modules/<module-name>/{main,variables,outputs,versions}.tf
touch modules/<module-name>/README.md
```

## Template Files

### versions.tf
```hcl
terraform {
  required_version = ">= 1.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 4.0"
    }
  }
}
```

### variables.tf
```hcl
variable "project_id" {
  description = "The project ID"
  type        = string
}
```

### outputs.tf
```hcl
output "id" {
  description = "The ID of the created resource"
  value       = google_resource.main.id
}
```

## Relationship with terraform-module-library

- Use **terraform-module-creator** (this skill) for the initial file creation and setup.
- Use **terraform-module-library** for design patterns, best practices, and internal code logic.
