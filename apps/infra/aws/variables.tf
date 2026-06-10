variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ap-northeast-2"
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
  description = "VPC CIDR block"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "Availability zones"
  type        = list(string)
  default     = ["ap-northeast-2a", "ap-northeast-2c"]
}

# ECS - API
variable "api_cpu" {
  description = "API task CPU units"
  type        = number
  default     = 256
}

variable "api_memory" {
  description = "API task memory (MiB)"
  type        = number
  default     = 512
}

variable "api_desired_count" {
  description = "API desired task count"
  type        = number
  default     = 1

  validation {
    condition     = var.api_desired_count >= 1
    error_message = "api_desired_count must be at least 1."
  }
}

# ECS - Web
variable "web_cpu" {
  description = "Web task CPU units"
  type        = number
  default     = 256
}

variable "web_memory" {
  description = "Web task memory (MiB)"
  type        = number
  default     = 512
}

variable "web_desired_count" {
  description = "Web desired task count"
  type        = number
  default     = 1
}

# ECS - Worker
variable "worker_cpu" {
  description = "Worker task CPU units"
  type        = number
  default     = 256
}

variable "worker_memory" {
  description = "Worker task memory (MiB)"
  type        = number
  default     = 512
}

variable "worker_desired_count" {
  description = "Worker desired task count"
  type        = number
  default     = 1
}

# Database
variable "db_instance_class" {
  description = "Aurora instance class"
  type        = string
  default     = "db.t4g.medium"
}

variable "db_name" {
  description = "Database name"
  type        = string
  default     = "app"
}

variable "db_user" {
  description = "Database master user"
  type        = string
  default     = "app"
}

variable "rds_multi_az" {
  description = "Enable Multi-AZ for Aurora (2 cluster instances)"
  type        = bool
  default     = false
}

variable "rds_deletion_protection" {
  description = "Enable deletion protection for RDS (disable explicitly in dev tfvars)"
  type        = bool
  default     = true
}

variable "rds_backup_retention_period" {
  description = "RDS backup retention period in days"
  type        = number
  default     = 7
}

# Redis
variable "redis_node_type" {
  description = "ElastiCache node type"
  type        = string
  default     = "cache.t4g.micro"
}

# Autoscaling
variable "enable_autoscaling" {
  description = "Enable ECS autoscaling for the API service"
  type        = bool
  default     = false
}

variable "api_autoscale_min" {
  description = "Minimum API task count for autoscaling"
  type        = number
  default     = 1

  validation {
    condition     = var.api_autoscale_min >= 1
    error_message = "api_autoscale_min must be at least 1."
  }
}

variable "api_autoscale_max" {
  description = "Maximum API task count for autoscaling"
  type        = number
  default     = 5
}

variable "worker_autoscale_min" {
  description = "Minimum worker task count for autoscaling"
  type        = number
  default     = 1

  validation {
    condition     = var.worker_autoscale_min >= 1
    error_message = "worker_autoscale_min must be at least 1."
  }
}

variable "worker_autoscale_max" {
  description = "Maximum worker task count for autoscaling"
  type        = number
  default     = 2
}

variable "worker_queue_depth_target" {
  description = "Target visible messages on the default queue per worker task (scale out above this)"
  type        = number
  default     = 100
}

# WAF
variable "enable_waf" {
  description = "Attach a WAFv2 web ACL (rate limiting + AWS managed rules) to the ALB"
  type        = bool
  default     = true
}

variable "waf_block_oversize_body" {
  description = "Block request bodies larger than 8 KB — AWS's fixed WAF inspection cap on ALB, not adjustable. Default false: bodies over 8 KB pass with only the first 8 KB inspected; enforce the real max body size (e.g. 1 MiB) in the API layer"
  type        = bool
  default     = false
}

# Scheduler
variable "schedules" {
  description = "EventBridge schedules that publish to the SNS tasks topic. Use this instead of in-worker cron so each tick runs exactly once across worker instances"
  type = map(object({
    schedule_expression = string # e.g. "rate(5 minutes)" or "cron(0 3 * * ? *)"
    payload             = string # SNS message body consumed by the worker
  }))
  default = {}
}

# Domain
variable "domain" {
  description = "Custom domain for the application (leave empty to use ALB DNS over HTTP)"
  type        = string
  default     = ""
}

variable "api_subdomain" {
  description = "API subdomain"
  type        = string
  default     = "api"
}

variable "acm_certificate_arn" {
  description = "ACM certificate ARN for HTTPS (required when domain is set)"
  type        = string
  default     = ""
}

# SES
variable "ses_domain" {
  description = "Domain identity for SES email sending (leave empty to skip SES setup)"
  type        = string
  default     = ""
}

# GitHub Repository (for OIDC)
variable "github_repository" {
  description = "GitHub repository in format 'owner/repo'"
  type        = string
}

# Monitoring
variable "enable_monitoring" {
  description = "Enable CloudWatch dashboard, alarms, and SNS alarm topic"
  type        = bool
  default     = true
}

variable "alarm_email" {
  description = "Email address for CloudWatch alarm notifications (required in prod)"
  type        = string
  default     = ""

  validation {
    condition     = var.alarm_email == "" || can(regex("^[^@]+@[^@]+\\.[^@]+$", var.alarm_email))
    error_message = "alarm_email must be a valid email address or empty."
  }
}

# Secrets (passed via Infisical)
variable "DATABASE_PASSWORD" {
  description = "Database master user password"
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
