locals {
  supabase_url = "https://${supabase_project.main.id}.supabase.co"

  api_env_vars = {
    SUPABASE_URL       = local.supabase_url
    B2_KEY_ID          = b2_application_key.main.application_key_id
    B2_APPLICATION_KEY = b2_application_key.main.application_key
    B2_BUCKET_NAME     = b2_bucket.main.bucket_name
  }

  web_env_vars = {
    NEXT_PUBLIC_SUPABASE_URL = local.supabase_url
  }
}
