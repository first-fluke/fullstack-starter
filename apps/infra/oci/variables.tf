variable "region" {
  description = "OCI region"
  type        = string
  default     = "ap-seoul-1"
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

# Provider auth (leave user/fingerprint/key null to use ~/.oci/config)
variable "tenancy_ocid" {
  description = "Tenancy OCID (also used for dynamic groups and the OCIR namespace)"
  type        = string
}

variable "user_ocid" {
  description = "User OCID for API key auth (null to use config_file_profile)"
  type        = string
  default     = null
}

variable "fingerprint" {
  description = "API key fingerprint (null to use config_file_profile)"
  type        = string
  default     = null
}

variable "private_key_path" {
  description = "Path to the API private key (null to use config_file_profile)"
  type        = string
  default     = null
}

variable "config_file_profile" {
  description = "Profile in ~/.oci/config to use when explicit credentials are not set"
  type        = string
  default     = null
}

# Compartment
variable "parent_compartment_ocid" {
  description = "Parent compartment OCID under which the app_name-environment child compartment is created (can be the tenancy root OCID)"
  type        = string
}

# Network
variable "vcn_cidr" {
  description = "VCN CIDR block"
  type        = string
  default     = "10.0.0.0/16"
}

# Container Instances - API
variable "container_shape" {
  description = "Container instance shape (CI.Standard.E4.Flex for x86, CI.Standard.A1.Flex for cheaper Arm — images must match the architecture)"
  type        = string
  default     = "CI.Standard.E4.Flex"
}

variable "api_ocpus" {
  description = "API container instance OCPUs"
  type        = number
  default     = 1
}

variable "api_memory_in_gbs" {
  description = "API container instance memory (GB)"
  type        = number
  default     = 2
}

variable "api_count" {
  description = "Number of API container instances (no autoscaling on OCI Container Instances — scale by raising this count, see README)"
  type        = number
  default     = 1

  validation {
    condition     = var.api_count >= 1
    error_message = "api_count must be at least 1."
  }
}

# Container Instances - Web
variable "web_ocpus" {
  description = "Web container instance OCPUs"
  type        = number
  default     = 1
}

variable "web_memory_in_gbs" {
  description = "Web container instance memory (GB)"
  type        = number
  default     = 2
}

variable "web_count" {
  description = "Number of Web container instances"
  type        = number
  default     = 1
}

# Container Instances - Worker
variable "worker_ocpus" {
  description = "Worker container instance OCPUs"
  type        = number
  default     = 1
}

variable "worker_memory_in_gbs" {
  description = "Worker container instance memory (GB)"
  type        = number
  default     = 2
}

variable "worker_count" {
  description = "Number of worker container instances (guidance: keep <= 2 — queue consumers are competing, mirror aws worker_autoscale_max)"
  type        = number
  default     = 1
}

# Database (OCI Database with PostgreSQL)
variable "db_shape" {
  description = "PostgreSQL DB system shape (list region shapes with: oci psql shape-collection list-shapes)"
  type        = string
  default     = "PostgreSQL.VM.Standard.E4.Flex"
}

variable "db_ocpus" {
  description = "PostgreSQL OCPUs per instance (flex shapes only)"
  type        = number
  default     = 2
}

variable "db_memory_in_gbs" {
  description = "PostgreSQL memory per instance in GB (flex shapes only)"
  type        = number
  default     = 32
}

variable "db_instance_count" {
  description = "PostgreSQL instance node count (1 = single node; >1 adds HA standby / read replicas, see the read-scaling guide in postgres.tf)"
  type        = number
  default     = 1
}

variable "db_version" {
  description = "PostgreSQL major version"
  type        = string
  default     = "16"
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

variable "db_backup_retention_days" {
  description = "Daily backup retention in days"
  type        = number
  default     = 7
}

# Redis (OCI Cache)
variable "redis_node_count" {
  description = "OCI Cache cluster node count (1 = no replica; >=2 adds replicas with automatic failover)"
  type        = number
  default     = 1
}

variable "redis_memory_in_gbs" {
  description = "Memory per OCI Cache node in GB (minimum 2)"
  type        = number
  default     = 2
}

variable "redis_software_version" {
  description = "OCI Cache engine version (e.g. REDIS_7_0, VALKEY_7_2)"
  type        = string
  default     = "REDIS_7_0"
}

# Load Balancer
variable "lb_min_bandwidth_mbps" {
  description = "Flexible LB minimum bandwidth (10 Mbps is Always Free eligible)"
  type        = number
  default     = 10
}

variable "lb_max_bandwidth_mbps" {
  description = "Flexible LB maximum bandwidth"
  type        = number
  default     = 10
}

# WAF
variable "enable_waf" {
  description = "Attach a WAF policy (rate limiting) to the load balancer"
  type        = bool
  default     = true
}

# Scheduler
variable "schedules" {
  description = "Cron-style scheduled jobs that should publish to the default queue. NOT IMPLEMENTED on OCI — there is no EventBridge/Cloud Scheduler equivalent that can publish a payload to a queue (see scheduler.tf and README Notes)"
  type = map(object({
    schedule_expression = string # e.g. "0 3 * * *"
    payload             = string # message body the worker would consume
  }))
  default = {}
}

# Domain
variable "domain" {
  description = "Custom domain for the application (leave empty to use the LB public IP over HTTP)"
  type        = string
  default     = ""
}

variable "api_subdomain" {
  description = "API subdomain"
  type        = string
  default     = "api"
}

variable "certificate_ocid" {
  description = "OCI Certificates service certificate OCID for HTTPS (required when domain is set)"
  type        = string
  default     = ""
}

# GitHub Repository (for OIDC)
variable "github_repository" {
  description = "GitHub repository in format 'owner/repo'"
  type        = string
}

variable "identity_domain_ocid" {
  description = "Identity domain OCID used for GitHub Actions OIDC federation (identity propagation trust). Leave empty to skip CI identity provisioning — see README CI/CD section"
  type        = string
  default     = ""
}

# Monitoring
variable "enable_monitoring" {
  description = "Enable ONS alarm topic and monitoring alarms"
  type        = bool
  default     = true
}

variable "alarm_email" {
  description = "Email address for alarm notifications (required in prod)"
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
