resource "supabase_project" "main" {
  organization_id   = var.supabase_org_id
  name              = var.project_prefix
  database_password = var.supabase_db_password
  region            = var.supabase_region
}
