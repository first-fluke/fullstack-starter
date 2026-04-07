# Hackathon Infrastructure Design

## Overview

`apps/infra/hackathon/`에 Vercel + Supabase + Backblaze B2 + Weaviate Cloud를 프로비저닝하는 독립 인프라 구성.
기존 `apps/infra/` (GCP)와 완전 독립. state/provider 분리.

## Approach: Terraform + mise hybrid (Approach B)

- **Terraform**: 공식 provider 있는 서비스 (Vercel, Supabase, B2)
- **bun scripts**: provider 없는 서비스 (Weaviate Cloud) + Supabase key 조회 + env 동기화
- **mise**: 전체 lifecycle 오케스트레이션

## Architecture

```
apps/infra/hackathon/
├── versions.tf                 # provider 선언 (vercel ~>4.0, supabase ~>1.0, b2 ~>0.8)
├── provider.tf                 # provider 설정 + 인증
├── variables.tf                # 입력 변수
├── terraform.tfvars.example    # 변수 예시
├── locals.tf                   # Supabase URL 구성 등
├── vercel.tf                   # Vercel 프로젝트 x2 (api, web) + 환경변수 주입
├── supabase.tf                 # Supabase 프로젝트 생성 (id만 반환)
├── b2.tf                       # B2 버킷 + 앱 키
├── outputs.tf                  # 프로비저닝 결과 출력
├── scripts/
│   ├── weaviate.ts             # WCD 클러스터 CRUD (idempotent)
│   ├── supabase-keys.ts        # Supabase API keys 조회
│   ├── env-sync.ts             # Vercel env 주입 + .env.example 슬롯 추가
│   ├── status.ts               # 전체 서비스 health check
│   └── package.json            # 스크립트 의존성
├── .gitignore
└── mise.toml                   # lifecycle 오케스트레이션
```

## Data Flow

```
mise run setup
  ├─ mise run apply             (Vercel + Supabase + B2 프로비저닝)
  │    ├─ Vercel API project
  │    ├─ Vercel Web project
  │    ├─ Supabase project
  │    └─ B2 bucket + key
  │
  ├─ mise run weaviate:up       (WCD REST API로 클러스터 생성)
  │
  └─ mise run env:sync
       ├─ terraform output → 값 수집
       ├─ supabase-keys.ts → anon_key 조회
       ├─ Vercel env에 누락된 값만 추가 (덮어쓰지 않음)
       └─ apps/api/.env.example, apps/web/.env.example에 슬롯 추가
```

## Terraform Resources

### versions.tf

```hcl
terraform {
  required_version = ">= 1.9.0"

  required_providers {
    vercel = {
      source  = "vercel/vercel"
      version = "~> 4.0"
    }
    supabase = {
      source  = "supabase/supabase"
      version = "~> 1.0"
    }
    b2 = {
      source  = "Backblaze/b2"
      version = "~> 0.8"
    }
  }
}
```

### vercel.tf

```hcl
resource "vercel_project" "api" {
  name      = "${var.project_prefix}-api"
  framework = null  # Python serverless — framework 미지정이 안전

  git_repository {
    type = "github"
    repo = var.github_repo
  }

  root_directory = "apps/api"
}

resource "vercel_project" "web" {
  name      = "${var.project_prefix}-web"
  framework = "nextjs"

  git_repository {
    type = "github"
    repo = var.github_repo
  }

  root_directory = "apps/web"
}

resource "vercel_project_environment_variable" "api_vars" {
  for_each = local.api_env_vars

  project_id = vercel_project.api.id
  key        = each.key
  value      = each.value
  target     = ["production", "preview"]
}

resource "vercel_project_environment_variable" "web_vars" {
  for_each = local.web_env_vars

  project_id = vercel_project.web.id
  key        = each.key
  value      = each.value
  target     = ["production", "preview"]
}
```

### supabase.tf

```hcl
resource "supabase_project" "main" {
  organization_id   = var.supabase_org_id
  name              = var.project_prefix
  database_password  = var.supabase_db_password
  region            = var.supabase_region
}
```

> Note: `supabase_project`는 `id`만 반환. URL은 `https://${id}.supabase.co`로 구성, anon_key는 scripts/supabase-keys.ts로 별도 조회.

### b2.tf

```hcl
resource "b2_bucket" "main" {
  bucket_name = "${var.project_prefix}-storage"
  bucket_type = "allPrivate"
}

resource "b2_application_key" "main" {
  key_name     = "${var.project_prefix}-key"
  bucket_id    = b2_bucket.main.bucket_id
  capabilities = ["readFiles", "writeFiles", "listFiles", "deleteFiles"]
}
```

### locals.tf

```hcl
locals {
  supabase_url = "https://${supabase_project.main.id}.supabase.co"

  api_env_vars = {
    SUPABASE_URL       = local.supabase_url
    B2_KEY_ID          = b2_application_key.main.application_key_id
    B2_APPLICATION_KEY = b2_application_key.main.application_key
    B2_BUCKET_NAME     = b2_bucket.main.bucket_name
    # SUPABASE_ANON_KEY, WEAVIATE_URL, WEAVIATE_API_KEY → env-sync.ts에서 주입
  }

  web_env_vars = {
    NEXT_PUBLIC_SUPABASE_URL = local.supabase_url
    # NEXT_PUBLIC_SUPABASE_ANON_KEY → env-sync.ts에서 주입
  }
}
```

### variables.tf

```hcl
variable "project_prefix" {
  type        = string
  description = "Prefix for all resource names"
}

variable "github_repo" {
  type        = string
  description = "GitHub repository (owner/repo)"
}

variable "supabase_org_id" {
  type        = string
  description = "Supabase organization slug"
}

variable "supabase_db_password" {
  type        = string
  sensitive   = true
  description = "Supabase database password"
}

variable "supabase_region" {
  type        = string
  default     = "ap-northeast-2"
  description = "Supabase project region"
}
```

### provider.tf

```hcl
provider "vercel" {
  # VERCEL_API_TOKEN 환경변수로 인증
}

provider "supabase" {
  # SUPABASE_ACCESS_TOKEN 환경변수로 인증
}

provider "b2" {
  # B2_APPLICATION_KEY_ID, B2_APPLICATION_KEY 환경변수로 인증
}
```

### outputs.tf

```hcl
output "vercel_api_project_id" {
  value = vercel_project.api.id
}

output "vercel_web_project_id" {
  value = vercel_project.web.id
}

output "supabase_project_id" {
  value = supabase_project.main.id
}

output "supabase_url" {
  value = local.supabase_url
}

output "b2_bucket_name" {
  value = b2_bucket.main.bucket_name
}

output "b2_key_id" {
  value = b2_application_key.main.application_key_id
}

output "b2_app_key" {
  value     = b2_application_key.main.application_key
  sensitive = true
}
```

## mise.toml

```toml
[tasks]
# === Full lifecycle (순차 실행) ===
[tasks.setup]
description = "Provision everything"
run = ["mise run apply", "mise run weaviate:up", "mise run env:sync"]

[tasks.teardown]
description = "Destroy everything"
run = ["mise run weaviate:down", "mise run destroy"]

# === Terraform ===
init = { run = "terraform init", description = "Initialize Terraform" }
plan = { run = "terraform plan", description = "Plan infrastructure" }
apply = { run = "terraform apply", description = "Apply infrastructure" }
destroy = { run = "terraform destroy", description = "Destroy infrastructure" }
fmt = { run = "terraform fmt -recursive", description = "Format Terraform" }
validate = { run = "terraform validate", description = "Validate Terraform" }
output = { run = "terraform output -json", description = "Show Terraform outputs" }

# === Weaviate Cloud ===
"weaviate:up" = { run = "bun run scripts/weaviate.ts up", description = "Create WCD cluster" }
"weaviate:down" = { run = "bun run scripts/weaviate.ts down", description = "Delete WCD cluster" }
"weaviate:status" = { run = "bun run scripts/weaviate.ts status", description = "Check WCD cluster" }

# === Ops ===
"env:sync" = { run = "bun run scripts/env-sync.ts", description = "Sync env vars to Vercel + .env.example" }
status = { run = "bun run scripts/status.ts", description = "Check all provisioned resources" }
```

## Scripts (TypeScript / bun)

### weaviate.ts
- WCD REST API (`https://api.wcs.weaviate.io/v1`) 로 클러스터 CRUD
- 상태 파일: `.weaviate-state.json` (gitignored)
- `up`: 기존 클러스터 있으면 스킵 (idempotent)
- `down`: state 파일 없으면 스킵
- `status`: WCD API에서 클러스터 상태 조회

### supabase-keys.ts
- Supabase Management API로 project API keys 조회
- `supabase` CLI 있으면 CLI 사용, 없으면 REST API fallback
- 프로젝트 생성 직후 지연 가능 → retry + backoff 포함

### env-sync.ts
- `terraform output -json` + `.weaviate-state.json` + `supabase-keys.ts` 결과 수집
- Vercel env: 이미 있는 키는 스킵, 없는 것만 추가
- `.env.example`: 키 슬롯만 추가 (값 없이)

### status.ts
- 각 서비스 health check 후 상태 출력:
  ```
  Vercel API    ✓ hackathon-api (production)
  Vercel Web    ✓ hackathon-web (production)
  Supabase      ✓ https://xxx.supabase.co
  B2 Bucket     ✓ hackathon-storage
  Weaviate      ✓ https://xxx.weaviate.network
  ```

## Authentication

| Service | Method | Variable |
|---------|--------|----------|
| Vercel | API Token | `VERCEL_API_TOKEN` |
| Supabase | Access Token | `SUPABASE_ACCESS_TOKEN` |
| B2 | Application Key | `B2_APPLICATION_KEY_ID` + `B2_APPLICATION_KEY` |
| Weaviate Cloud | API Key | `WCD_API_KEY` |

모든 시크릿은 `terraform.tfvars` (gitignored) 또는 환경변수로 주입.

## .env.example Slots

### apps/api/.env.example

```
SUPABASE_URL=
SUPABASE_ANON_KEY=
WEAVIATE_URL=
WEAVIATE_API_KEY=
B2_KEY_ID=
B2_APPLICATION_KEY=
B2_BUCKET_NAME=
```

### apps/web/.env.example

```
NEXT_PUBLIC_SUPABASE_URL=
NEXT_PUBLIC_SUPABASE_ANON_KEY=
```

## .gitignore

```
*.tfstate
*.tfstate.backup
.terraform/
*.tfvars
!terraform.tfvars.example
.weaviate-state.json
scripts/node_modules/
.env
```

## Edge Cases

| Situation | Handling |
|-----------|----------|
| `setup` 중간 실패 | 각 스크립트 idempotent → 재실행으로 복구 |
| Supabase key 조회 지연 | retry + backoff |
| Vercel env 키 중복 | 존재 여부 체크 후 스킵 |
| `.weaviate-state.json` 유실 | `weaviate:status`로 WCD API에서 이름 매칭 복구 |
| B2 버킷에 파일 남아있을 때 destroy | 수동 비우기 필요 → 에러 메시지로 안내 |
| 환경변수 누락 | 스크립트 진입 시 필수 변수 체크 → 명확한 에러 출력 |

## CLI Usage

```bash
cd apps/infra/hackathon

# 초기화
mise run init

# 전체 프로비저닝
mise run setup

# 상태 확인
mise run status

# 개별 조작
mise run plan
mise run weaviate:status
mise run env:sync

# 전체 정리
mise run teardown
```
