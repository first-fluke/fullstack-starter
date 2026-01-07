# Fullstack Starter

English | [한국어](./README.ko.md)

Production-ready fullstack monorepo template with Next.js 16, FastAPI, Flutter, and GCP infrastructure.

## Key Features

- **Modern Stack**: Next.js 16 + React 19, FastAPI, Flutter 3.32, TailwindCSS v4
- **Type Safety**: Full type support with TypeScript, Pydantic, and Dart
- **Authentication**: OAuth with better-auth (Google, GitHub, Facebook)
- **Internationalization**: next-intl (web), Flutter ARB (mobile), shared i18n package
- **Auto-generated API Clients**: Orval (web), swagger_parser (mobile)
- **Infrastructure as Code**: Terraform + GCP (Cloud Run, Cloud SQL, Cloud Storage)
- **CI/CD**: GitHub Actions + Workload Identity Federation (keyless deployment)
- **AI Agent Support**: Guidelines for AI coding agents (Gemini, Claude, etc.)
- **mise Monorepo**: mise-based task management and unified tool versions

## Tech Stack

| Layer | Technology |
|-------|------------|
| **Frontend** | Next.js 16, React 19, TailwindCSS v4, shadcn/ui, TanStack Query, Jotai |
| **Backend** | FastAPI, SQLAlchemy (async), PostgreSQL 16, Redis 7 |
| **Mobile** | Flutter 3.32, Riverpod 3, go_router 17, Firebase Crashlytics, Fastlane |
| **Worker** | FastAPI + CloudTasks/PubSub |
| **Infrastructure** | Terraform, GCP (Cloud Run, Cloud SQL, Cloud Storage, CDN) |
| **CI/CD** | GitHub Actions, Workload Identity Federation |
| **Tool Management** | mise (unified Node, Python, Flutter, Terraform versions) |

## Prerequisites

- [mise](https://mise.jdx.dev/) - Runtime version manager
- [Docker](https://www.docker.com/) - Local infrastructure
- [Terraform](https://www.terraform.io/) - Cloud infrastructure (optional)

## Quick Start

### 1. Install Runtimes

```bash
# Install mise (if not installed)
curl https://mise.run | sh

# Install all runtimes (Node 24, Python 3.13, Flutter 3, pnpm 10, uv, Terraform)
mise install
```

### 2. Install Dependencies

```bash
# Root dependencies (JS/TS)
pnpm install

# API dependencies
cd apps/api && uv sync --frozen

# Worker dependencies
cd apps/worker && uv sync --frozen

# Mobile dependencies
cd apps/mobile && flutter pub get
```

### 3. Start Local Infrastructure

```bash
mise //apps/api:infra:up
```

This starts:
- PostgreSQL (5432)
- Redis (6379)
- MinIO (9000, 9001)

### 4. Run Database Migrations

```bash
mise //apps/api:migrate
```

### 5. Start Development Servers

```bash
# Start all services (recommended)
mise dev

# Or start individually
mise //apps/api:dev    # API server
mise //apps/web:dev    # Web server
mise //apps/worker:dev # Worker
```

## Project Structure

```
fullstack-starter/
├── apps/
│   ├── api/           # FastAPI backend
│   ├── web/           # Next.js frontend
│   ├── worker/        # Background worker
│   ├── mobile/        # Flutter mobile app
│   └── infra/         # Terraform infrastructure
├── packages/
│   └── i18n/          # Shared i18n package (Source of Truth)
├── .agent/rules/      # AI agent guidelines
├── .serena/           # Serena MCP config
└── .github/workflows/ # CI/CD
```

## Commands

### mise Monorepo Tasks

This project uses mise monorepo mode with `//path:task` syntax.

```bash
# List all available tasks
mise tasks --all
```

| Command | Description |
|---------|-------------|
| `mise dev` | Start all services |
| `mise lint` | Lint all apps |
| `mise format` | Format all apps |
| `mise test` | Test all apps |
| `mise typecheck` | Type check |
| `mise i18n:build` | Build i18n files |
| `mise gen:api` | Generate OpenAPI schema and API clients |

### App-specific Tasks

<details>
<summary>API (apps/api)</summary>

| Command | Description |
|---------|-------------|
| `mise //apps/api:dev` | Start development server |
| `mise //apps/api:test` | Run tests |
| `mise //apps/api:lint` | Run linter |
| `mise //apps/api:format` | Format code |
| `mise //apps/api:migrate` | Run migrations |
| `mise //apps/api:migrate:create` | Create new migration |
| `mise //apps/api:gen:openapi` | Generate OpenAPI schema |
| `mise //apps/api:infra:up` | Start local infrastructure |
| `mise //apps/api:infra:down` | Stop local infrastructure |

</details>

<details>
<summary>Web (apps/web)</summary>

| Command | Description |
|---------|-------------|
| `mise //apps/web:dev` | Start development server |
| `mise //apps/web:build` | Production build |
| `mise //apps/web:test` | Run tests |
| `mise //apps/web:lint` | Run linter |
| `mise //apps/web:gen:api` | Generate API client |

</details>

<details>
<summary>Mobile (apps/mobile)</summary>

| Command | Description |
|---------|-------------|
| `mise //apps/mobile:dev` | Run on device/simulator |
| `mise //apps/mobile:build` | Build |
| `mise //apps/mobile:test` | Run tests |
| `mise //apps/mobile:lint` | Run analyzer |
| `mise //apps/mobile:gen:l10n` | Generate localizations |
| `mise //apps/mobile:gen:api` | Generate API client |

</details>

<details>
<summary>Worker (apps/worker)</summary>

| Command | Description |
|---------|-------------|
| `mise //apps/worker:dev` | Start worker |
| `mise //apps/worker:test` | Run tests |
| `mise //apps/worker:lint` | Run linter |

</details>

<details>
<summary>Infrastructure (apps/infra)</summary>

| Command | Description |
|---------|-------------|
| `mise //apps/infra:init` | Initialize Terraform |
| `mise //apps/infra:plan` | Preview changes |
| `mise //apps/infra:apply` | Apply changes |
| `mise //apps/infra:plan:prod` | Preview production |
| `mise //apps/infra:apply:prod` | Apply production |

</details>

<details>
<summary>i18n (packages/i18n)</summary>

| Command | Description |
|---------|-------------|
| `mise //packages/i18n:build` | Build i18n files for web and mobile |
| `mise //packages/i18n:build:web` | Build for web only |
| `mise //packages/i18n:build:mobile` | Build for mobile only |

</details>

## Internationalization (i18n)

`packages/i18n` is the Single Source of Truth for i18n resources.

```bash
# Edit i18n files
packages/i18n/source/en.arb  # English (default)
packages/i18n/source/ko.arb  # Korean
packages/i18n/source/ja.arb  # Japanese

# Build and deploy to each app
mise i18n:build
# Generated files:
# - apps/web/messages/*.json (Nested JSON)
# - apps/mobile/lib/l10n/app_*.arb (Flutter ARB)
```

## Configuration

### Environment Variables

Copy example files and configure:

```bash
# API
cp apps/api/.env.example apps/api/.env

# Web
cp apps/web/.env.example apps/web/.env

# Infra
cp apps/infra/terraform.tfvars.example apps/infra/terraform.tfvars
```

### GitHub Actions Secrets

Set these secrets in your repository:

| Secret | Description |
|--------|-------------|
| `GCP_PROJECT_ID` | GCP project ID |
| `GCP_REGION` | GCP region (e.g., `asia-northeast3`) |
| `WORKLOAD_IDENTITY_PROVIDER` | From Terraform output |
| `GCP_SERVICE_ACCOUNT` | From Terraform output |
| `FIREBASE_SERVICE_ACCOUNT_JSON` | Firebase service account JSON (for mobile deployment) |
| `FIREBASE_ANDROID_APP_ID` | Firebase Android app ID |

## Deployment

### GitHub Actions (Recommended)

Push to `main` branch triggers automatic deployment:
- `apps/api/` changes → Deploy API
- `apps/web/` changes → Deploy Web
- `apps/worker/` changes → Deploy Worker
- `apps/mobile/` changes → Build & Deploy to Firebase App Distribution

### Manual Deployment

```bash
# Build and push Docker images
cd apps/api
docker build -t gcr.io/PROJECT_ID/api .
docker push gcr.io/PROJECT_ID/api

# Deploy to Cloud Run
gcloud run deploy api --image gcr.io/PROJECT_ID/api --region REGION
```

## Mobile Setup

### Firebase Configuration

1. Install FlutterFire CLI:

```bash
dart pub global activate flutterfire_cli
```

2. Configure Firebase for your project:

```bash
cd apps/mobile
flutterfire configure
```

This generates `lib/firebase_options.dart` with your Firebase configuration.

### Fastlane

The mobile app uses Fastlane for build automation and deployment.

```bash
cd apps/mobile

# Install Ruby dependencies
bundle install

# Available lanes
bundle exec fastlane android build       # Build APK
bundle exec fastlane android firebase    # Deploy to Firebase App Distribution
bundle exec fastlane android internal    # Deploy to Play Store (internal)
bundle exec fastlane ios build           # Build iOS (no codesign)
bundle exec fastlane ios testflight_deploy  # Deploy to TestFlight
```

## AI Agent Support

This template is designed to work with AI coding agents (Gemini, Claude, etc.).

- `.agent/rules/` - Guidelines for AI agents
- `.serena/` - Serena MCP configuration

## Documentation

- [Build Guide](.agent/rules/build-guide.md)
- [Lint & Format Guide](.agent/rules/lint-format-guide.md)
- [Test Guide](.agent/rules/test-guide.md)

## License

MIT

## Sponsors

If this project helped you, please consider buying me a coffee!

<a href="https://www.buymeacoffee.com/firstfluke" target="_blank"><img src="https://cdn.buymeacoffee.com/buttons/v2/default-yellow.png" alt="Buy Me A Coffee" style="height: 60px !important;width: 217px !important;" ></a>
