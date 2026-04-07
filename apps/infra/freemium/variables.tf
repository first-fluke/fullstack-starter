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
