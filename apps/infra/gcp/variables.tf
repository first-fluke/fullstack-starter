variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "region" {
  description = "GCP region"
  type        = string
  default     = "asia-northeast3"
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
variable "vpc_cidr" {
  description = "CIDR block for VPC subnet"
  type        = string
  default     = "10.0.0.0/16"
}

# Database
variable "db_tier" {
  description = "Cloud SQL instance tier"
  type        = string
  default     = "db-f1-micro"
}

variable "db_name" {
  description = "Database name"
  type        = string
  default     = "app"
}

variable "db_user" {
  description = "Database user"
  type        = string
  default     = "app"
}

# Redis
variable "redis_memory_size_gb" {
  description = "Redis memory size in GB"
  type        = number
  default     = 1
}

# Cloud Run
variable "api_cpu" {
  description = "API Cloud Run CPU"
  type        = string
  default     = "1"
}

variable "api_memory" {
  description = "API Cloud Run memory"
  type        = string
  default     = "512Mi"
}

variable "api_min_instances" {
  description = "API minimum instances (keep at least 1 to avoid cold starts)"
  type        = number
  default     = 1

  validation {
    condition     = var.api_min_instances >= 1
    error_message = "api_min_instances must be at least 1."
  }
}

variable "api_max_instances" {
  description = "API maximum instances"
  type        = number
  default     = 10
}

variable "web_cpu" {
  description = "Web Cloud Run CPU"
  type        = string
  default     = "1"
}

variable "web_memory" {
  description = "Web Cloud Run memory"
  type        = string
  default     = "512Mi"
}

variable "web_min_instances" {
  description = "Web minimum instances"
  type        = number
  default     = 0
}

variable "web_max_instances" {
  description = "Web maximum instances"
  type        = number
  default     = 10
}

variable "worker_cpu" {
  description = "Worker Cloud Run CPU"
  type        = string
  default     = "1"
}

variable "worker_memory" {
  description = "Worker Cloud Run memory"
  type        = string
  default     = "512Mi"
}

variable "worker_min_instances" {
  description = "Worker minimum instances"
  type        = number
  default     = 0
}

variable "worker_max_instances" {
  description = "Worker maximum instances"
  type        = number
  default     = 5
}

# Domain
variable "domain" {
  description = "Custom domain for the application"
  type        = string
  default     = ""
}

variable "api_subdomain" {
  description = "API subdomain"
  type        = string
  default     = "api"
}

# GitHub Repository (for WIF)
variable "github_repository" {
  description = "GitHub repository in format 'owner/repo'"
  type        = string
}

# Scheduler
variable "schedules" {
  description = "Cloud Scheduler jobs that publish to the Pub/Sub tasks topic. Use this instead of in-worker cron so each tick runs exactly once across worker instances"
  type = map(object({
    schedule_expression = string # unix-cron, e.g. "0 3 * * *"
    payload             = string # Pub/Sub message body consumed by the worker
  }))
  default = {}
}

# CI/CD
variable "git_sha" {
  description = "Git commit SHA for release tracking (passed from CI/CD)"
  type        = string
  default     = "latest"
}

# Secrets (passed via Infisical)
variable "DATABASE_PASSWORD" {
  description = "Database user password"
  type        = string
  sensitive   = true
}

variable "DATABASE_URL" {
  description = "Full database connection URL"
  type        = string
  sensitive   = true
  default     = ""
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

# Internal
variable "API_URL" {
  description = "Internal API URL for service-to-service communication"
  type        = string
  default     = ""
}
