---
name: devops-iac-engineer
description: Expert guidance for designing, implementing, and maintaining cloud infrastructure using Experience in Infrastructure as Code (IaC) principles. Use this skill for architecting cloud solutions, setting up CI/CD pipelines, implementing observability, and following SRE best practices.
---

# DevOps IaC Engineer

This skill provides expertise in designing and managing cloud infrastructure using Infrastructure as Code (IaC) and DevOps/SRE best practices.

## When to Use

- Designing cloud architecture (AWS, GCP, Azure)
- Implementing or refactoring CI/CD pipelines
- Setting up observability (logging, metrics, tracing)
- Creating Kubernetes clusters and container orchestration strategies
- Implementing security controls and compliance checks
- Improving system reliability (SLO/SLA, Disaster Recovery)

## Infrastructure as Code (IaC) Principles

- **Declarative Code**: Use Terraform/OpenTofu to define the desired state.
- **GitOps**: Code repository is the single source of truth. Changes are applied via PRs and automated pipelines.
- **Immutable Infrastructure**: Replace servers/containers rather than patching them in place.

## Core Domains

### 1. Terraform & IaC
- Use modules for reusability.
- Separate state by environment (dev, stage, prod) and region.
- Automate `plan` and `apply` in CI/CD.

### 2. Kubernetes & Containers
- Build small, stateless containers.
- Use Helm or Kustomize for resource management.
- Implement resource limits and requests.
- Use namespaces for isolation.

### 3. CI/CD Pipelines
- **CI**: Lint, test, build, and scan (security) on every commit.
- **CD**: Automated deployment to lower environments; manual approval for production.
- Use tools like GitHub Actions, Cloud Build, or ArgoCD.

### 4. Observability
- **Logs**: Centralized logging (e.g., Cloud Logging, ELK).
- **Metrics**: Prometheus/Grafana or Cloud Monitoring.
- **Tracing**: OpenTelemetry for distributed tracing.

### 5. Security (DevSecOps)
- Scan IaC for misconfigurations (e.g., Checkov, Trivy).
- Manage secrets utilizing Secret Manager or Vault (never in code).
- Least privilege IAM roles.

## SRE Practices

- **SLI/SLO**: Define Service Level Indicators and Objectives for critical user journeys.
- **Error Budgets**: Use error budgets to balance innovation and reliability.
- **Post-Mortems**: Conduct blameless post-mortems for incidents.
