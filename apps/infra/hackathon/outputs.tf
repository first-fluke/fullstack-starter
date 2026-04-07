output "vercel_api_project_id" {
  value       = vercel_project.api.id
  description = "Vercel API project ID"
}

output "vercel_web_project_id" {
  value       = vercel_project.web.id
  description = "Vercel Web project ID"
}

output "supabase_project_id" {
  value       = supabase_project.main.id
  description = "Supabase project ID"
}

output "supabase_url" {
  value       = local.supabase_url
  description = "Supabase project URL"
}

output "b2_bucket_name" {
  value       = b2_bucket.main.bucket_name
  description = "B2 bucket name"
}

output "b2_key_id" {
  value       = b2_application_key.main.application_key_id
  description = "B2 application key ID"
}

output "b2_app_key" {
  value       = b2_application_key.main.application_key
  sensitive   = true
  description = "B2 application key"
}
