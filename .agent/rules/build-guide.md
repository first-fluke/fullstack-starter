---
trigger: model_decision
description: when working for building, running, or deploying the project
---

# Build Guide

## Quick Start

### Prerequisites

Ensure you have `mise` installed for runtime management.

```bash
# Install all runtimes
mise install

# Verify versions
mise current
```

## Build Commands

This project uses mise monorepo mode with `//path:task` syntax.

### Root (All Apps)

```bash
# List all available tasks
mise tasks --all

# Start all services
mise dev

# Lint all apps
mise lint

# Format all apps
mise format

# Test all apps
mise test

# Type check all apps
mise typecheck

# Build i18n files
mise i18n:build

# Generate OpenAPI schema and API clients
mise gen:api
```

### API (apps/api)

```bash
# Start development server
mise //apps/api:dev

# Run tests
mise //apps/api:test

# Lint
mise //apps/api:lint

# Format
mise //apps/api:format

# Type check
mise //apps/api:typecheck

# Run DB migrations
mise //apps/api:migrate

# Create new migration
mise //apps/api:migrate:create

# Generate OpenAPI schema
mise //apps/api:gen:openapi

# Start local infrastructure (PostgreSQL, Redis, MinIO)
mise //apps/api:infra:up

# Stop local infrastructure
mise //apps/api:infra:down

# Build Docker image
docker build -t api apps/api
```

### Web (apps/web)

```bash
# Start development server
mise //apps/web:dev

# Production build
mise //apps/web:build

# Run tests
mise //apps/web:test

# Lint
mise //apps/web:lint

# Format
mise //apps/web:format

# Type check
mise //apps/web:typecheck

# Generate API client from OpenAPI
mise //apps/web:gen:api

# Build Docker image
docker build -t web apps/web
```

### Worker (apps/worker)

```bash
# Start worker
mise //apps/worker:dev

# Run tests
mise //apps/worker:test

# Lint
mise //apps/worker:lint

# Format
mise //apps/worker:format

# Build Docker image
docker build -t worker apps/worker
```

### Mobile (apps/mobile)

```bash
# Run on device/simulator
mise //apps/mobile:dev

# Build
mise //apps/mobile:build

# Run tests
mise //apps/mobile:test

# Analyze (lint)
mise //apps/mobile:lint

# Format
mise //apps/mobile:format

# Generate localizations
mise //apps/mobile:gen:l10n

# Generate API client from OpenAPI
mise //apps/mobile:gen:api
```

### Fastlane (Mobile CI/CD)

```bash
cd apps/mobile

# Install Ruby dependencies
bundle install

# Android
bundle exec fastlane android build       # Build APK
bundle exec fastlane android firebase    # Deploy to Firebase App Distribution

# iOS
bundle exec fastlane ios build           # Build iOS (no codesign)
bundle exec fastlane ios testflight_deploy  # Deploy to TestFlight
```

### Infrastructure (apps/infra)

```bash
# Initialize Terraform
mise //apps/infra:init

# Preview changes
mise //apps/infra:plan

# Apply changes
mise //apps/infra:apply

# Preview production changes
mise //apps/infra:plan:prod

# Apply production changes
mise //apps/infra:apply:prod
```

### i18n (packages/i18n)

```bash
# Build i18n files for web and mobile
mise //packages/i18n:build

# Build for web only
mise //packages/i18n:build:web

# Build for mobile only
mise //packages/i18n:build:mobile
```

## Docker Compose (Local Development)

### Start Infrastructure

```bash
mise //apps/api:infra:up
```

This starts:

- PostgreSQL (port 5432)
- Redis (port 6379)
- MinIO (ports 9000, 9001)

### Stop Infrastructure

```bash
mise //apps/api:infra:down
```

### Reset Infrastructure (with data)

```bash
docker compose -f apps/api/docker-compose.infra.yml down -v
```

## Database Migrations

### Create Migration

```bash
mise //apps/api:migrate:create "description of changes"
```

### Apply Migrations

```bash
mise //apps/api:migrate
```

### Rollback Migration

```bash
cd apps/api
uv run alembic downgrade -1
```

## Common Build Issues

### Python Import Errors

```bash
# Ensure virtual environment is activated
cd apps/api
uv sync --frozen
```

### Node Module Issues

```bash
# Clear node_modules and reinstall
rm -rf node_modules bun-lock.yaml
bun install
```

### Flutter Build Issues

```bash
# Clean and rebuild
flutter clean
flutter pub get
dart run build_runner build --delete-conflicting-outputs
```

### Terraform State Issues

```bash
cd apps/infra

# Refresh state from cloud
terraform refresh -var-file="terraform.tfvars"

# Import existing resource
terraform import -var-file="terraform.tfvars" google_storage_bucket.uploads your-bucket-name
```
