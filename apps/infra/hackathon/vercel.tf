resource "vercel_project" "api" {
  name           = "${var.project_prefix}-api"
  framework      = null
  root_directory = "apps/api"

  git_repository {
    type = "github"
    repo = var.github_repo
  }
}

resource "vercel_project_environment_variable" "api" {
  for_each = local.api_env_vars

  project_id = vercel_project.api.id
  key        = each.key
  value      = each.value
  target     = ["production", "preview"]
}

resource "vercel_project" "web" {
  name           = "${var.project_prefix}-web"
  framework      = "nextjs"
  root_directory = "apps/web"

  git_repository {
    type = "github"
    repo = var.github_repo
  }
}

resource "vercel_project_environment_variable" "web" {
  for_each = local.web_env_vars

  project_id = vercel_project.web.id
  key        = each.key
  value      = each.value
  target     = ["production", "preview"]
}
