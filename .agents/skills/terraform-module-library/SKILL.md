---
name: terraform-module-library
description: Expert guidance for creating, managing, and using Terraform modules. Use this skill when the user wants to create reusable infrastructure components, standardize Terraform patterns, or needs help with module structure and best practices for AWS, GCP, or Azure.
---

# Terraform Module Library

This skill provides standardized patterns and best practices for creating and using Terraform modules.

## When to Use

- Creating new reusable Terraform modules
- Refactoring existing Terraform code into modules
- Standardizing infrastructure patterns across the project
- implement specific infrastructure components (VPC, GKE, RDS, etc.) using best practices

## Module Structure

Standard directory structure for a Terraform module:

```
module-name/
├── main.tf       # Primary logic and resources
├── variables.tf  # Input variable definitions
├── outputs.tf    # Output value definitions
├── versions.tf   # Provider and Terraform version constraints
├── README.md     # Module documentation
└── examples/     # Example configurations
    └── complete/ # Full example usage
```

## Best Practices

### Cloud Providers

#### Google Cloud Platform (GCP)
- Use `google-beta` provider for beta features if necessary, but prefer GA.
- Follow Google's "Cloud Foundation Toolkit" patterns where applicable.
- Resource naming: Use standardized prefixes/suffixes (e.g., `gcp-vpc-{env}`).

#### AWS
- Use standard `aws` provider resources.
- Tag all resources with consistent tags (Owner, Environment, Project).

### General
- **Version Pinning**: Always pin provider and Terraform versions in `versions.tf`.
- **Variables**: Include `description` and `type` for all variables. Use `validation` blocks for constraints.
- **Outputs**: Document all outputs.
- **State**: Do not include backend configuration in modules; state is managed by the root configuration.

## Common Module Patterns

### Private Module Registry
If using a private registry, ensure source paths follow the registry's convention.

### Local Modules
For local development or monorepos:
```hcl
module "network" {
  source = "./modules/network"
  # ...
}
```

## Review Checklist

1. [ ] Does the module have a `README.md` with input/output documentation?
2. [ ] Are all variables typed and described?
3. [ ] Are resource names deterministic or correctly scoped?
4. [ ] Does it include `examples/`?
5. [ ] Is `terraform_remote_state` avoided within the module?
