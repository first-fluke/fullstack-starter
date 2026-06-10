provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      app         = var.app_name
      environment = var.environment
      managed_by  = "terraform"
    }
  }
}
