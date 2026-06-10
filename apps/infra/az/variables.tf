variable "location" {
  description = "Azure region"
  type        = string
  default     = "koreacentral"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "app_name" {
  description = "Application name prefix for resources"
  type        = string
  default     = "fullstack-starter"
}

# Network
variable "vnet_cidr" {
  description = "Virtual network CIDR block"
  type        = string
  default     = "10.0.0.0/16"
}

# Container Apps - API
variable "api_cpu" {
  description = "API container CPU cores (Consumption plan pairs: 0.25/0.5Gi, 0.5/1Gi, 1/2Gi, 2/4Gi)"
  type        = number
  default     = 0.25
}

variable "api_memory" {
  description = "API container memory"
  type        = string
  default     = "0.5Gi"
}

variable "api_min_replicas" {
  description = "API minimum replicas (keep at least 1 to avoid cold starts)"
  type        = number
  default     = 1

  validation {
    condition     = var.api_min_replicas >= 1
    error_message = "api_min_replicas must be at least 1."
  }
}

variable "api_max_replicas" {
  description = "API maximum replicas"
  type        = number
  default     = 10
}

variable "api_concurrent_requests" {
  description = "Concurrent HTTP requests per API replica before scaling out (KEDA http rule)"
  type        = number
  default     = 100
}

# Container Apps - Web
variable "web_cpu" {
  description = "Web container CPU cores"
  type        = number
  default     = 0.25
}

variable "web_memory" {
  description = "Web container memory"
  type        = string
  default     = "0.5Gi"
}

variable "web_min_replicas" {
  description = "Web minimum replicas"
  type        = number
  default     = 1
}

variable "web_max_replicas" {
  description = "Web maximum replicas"
  type        = number
  default     = 10
}

# Container Apps - Worker
variable "worker_cpu" {
  description = "Worker container CPU cores"
  type        = number
  default     = 0.25
}

variable "worker_memory" {
  description = "Worker container memory"
  type        = string
  default     = "0.5Gi"
}

variable "worker_min_replicas" {
  description = "Worker minimum replicas"
  type        = number
  default     = 1

  validation {
    condition     = var.worker_min_replicas >= 1
    error_message = "worker_min_replicas must be at least 1."
  }
}

variable "worker_max_replicas" {
  description = "Worker maximum replicas"
  type        = number
  default     = 2
}

variable "worker_queue_depth_target" {
  description = "Target active messages on the default Service Bus subscription per worker replica (scale out above this)"
  type        = number
  default     = 100
}

# Container Registry
variable "acr_sku" {
  description = "Azure Container Registry SKU (Basic, Standard, Premium)"
  type        = string
  default     = "Basic"
}

# Database
variable "db_sku_name" {
  description = "PostgreSQL Flexible Server SKU (e.g. B_Standard_B1ms dev, GP_Standard_D2ds_v5 prod)"
  type        = string
  default     = "B_Standard_B1ms"
}

variable "db_storage_mb" {
  description = "PostgreSQL storage in MB"
  type        = number
  default     = 32768
}

variable "db_name" {
  description = "Database name"
  type        = string
  default     = "app"
}

variable "db_user" {
  description = "Database admin user"
  type        = string
  default     = "app"
}

variable "db_high_availability" {
  description = "Enable zone-redundant HA standby (not supported on Burstable SKUs)"
  type        = bool
  default     = false
}

variable "db_backup_retention_days" {
  description = "PostgreSQL backup retention period in days (7-35)"
  type        = number
  default     = 7
}

variable "db_geo_redundant_backup" {
  description = "Enable geo-redundant backups for PostgreSQL"
  type        = bool
  default     = false
}

# Redis
variable "redis_sku_name" {
  description = "Azure Cache for Redis SKU (Basic dev, Standard prod)"
  type        = string
  default     = "Basic"
}

variable "redis_family" {
  description = "Redis SKU family (C for Basic/Standard, P for Premium)"
  type        = string
  default     = "C"
}

variable "redis_capacity" {
  description = "Redis cache size (C family: 0=250MB ... 6=53GB)"
  type        = number
  default     = 0
}

# Service Bus
variable "servicebus_sku" {
  description = "Service Bus namespace SKU (topics require Standard or Premium)"
  type        = string
  default     = "Standard"
}

# WAF
variable "enable_waf" {
  description = "Attach a Front Door WAF policy (rate-limit custom rule) to the CDN endpoint"
  type        = bool
  default     = true
}

# Scheduler
variable "schedules" {
  description = "Container Apps Jobs (cron) that run the worker image with TASK_PAYLOAD. Use this instead of in-worker cron so each tick runs exactly once across worker replicas"
  type = map(object({
    schedule_expression = string # unix-cron, e.g. "0 3 * * *"
    payload             = string # TASK_PAYLOAD env value consumed by the worker entrypoint
  }))
  default = {}

  validation {
    condition     = alltrue([for k in keys(var.schedules) : length("${var.app_name}-${var.environment}-${k}") <= 32])
    error_message = "Container Apps Job names are capped at 32 characters: shorten the schedule key so app_name-environment-key fits."
  }
}

# Domain
variable "domain" {
  description = "Custom domain for the application (leave empty to use the Container Apps default domain)"
  type        = string
  default     = ""
}

variable "api_subdomain" {
  description = "API subdomain"
  type        = string
  default     = "api"
}

# GitHub Repository (for OIDC)
variable "github_repository" {
  description = "GitHub repository in format 'owner/repo'"
  type        = string
}

# Monitoring
variable "enable_monitoring" {
  description = "Enable Monitor action group and metric alerts"
  type        = bool
  default     = true
}

variable "alarm_email" {
  description = "Email address for Azure Monitor alert notifications (required in prod)"
  type        = string
  default     = ""

  validation {
    condition     = var.alarm_email == "" || can(regex("^[^@]+@[^@]+\\.[^@]+$", var.alarm_email))
    error_message = "alarm_email must be a valid email address or empty."
  }
}

# Secrets (passed via Infisical)
variable "DATABASE_PASSWORD" {
  description = "Database admin user password"
  type        = string
  sensitive   = true
}

variable "JWT_SECRET" {
  description = "JWT signing secret"
  type        = string
  sensitive   = true
}

variable "BETTER_AUTH_SECRET" {
  description = "Better Auth secret key"
  type        = string
  sensitive   = true
}

# OAuth Providers
variable "GOOGLE_CLIENT_ID" {
  description = "Google OAuth client ID"
  type        = string
  default     = ""
}

variable "GOOGLE_CLIENT_SECRET" {
  description = "Google OAuth client secret"
  type        = string
  sensitive   = true
  default     = ""
}

variable "GITHUB_CLIENT_ID" {
  description = "GitHub OAuth client ID"
  type        = string
  default     = ""
}

variable "GITHUB_CLIENT_SECRET" {
  description = "GitHub OAuth client secret"
  type        = string
  sensitive   = true
  default     = ""
}

variable "KAKAO_CLIENT_ID" {
  description = "Kakao OAuth client ID"
  type        = string
  default     = ""
}

variable "KAKAO_CLIENT_SECRET" {
  description = "Kakao OAuth client secret"
  type        = string
  sensitive   = true
  default     = ""
}

# AI/ML
variable "OPENAI_API_KEY" {
  description = "OpenAI API key"
  type        = string
  sensitive   = true
  default     = ""
}

variable "ANTHROPIC_API_KEY" {
  description = "Anthropic API key"
  type        = string
  sensitive   = true
  default     = ""
}

variable "GOOGLE_AI_API_KEY" {
  description = "Google AI (Gemini) API key"
  type        = string
  sensitive   = true
  default     = ""
}

# Observability
variable "LANGFUSE_PUBLIC_KEY" {
  description = "Langfuse public key for LLM observability"
  type        = string
  default     = ""
}

variable "LANGFUSE_SECRET_KEY" {
  description = "Langfuse secret key"
  type        = string
  sensitive   = true
  default     = ""
}

# Push Notifications
variable "VAPID_PUBLIC_KEY" {
  description = "VAPID public key for web push"
  type        = string
  default     = ""
}

variable "VAPID_PRIVATE_KEY" {
  description = "VAPID private key for web push"
  type        = string
  sensitive   = true
  default     = ""
}
