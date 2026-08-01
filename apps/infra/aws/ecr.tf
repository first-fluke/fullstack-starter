# ECR Repositories
resource "aws_ecr_repository" "api" {
  name                 = "${var.app_name}/api"
  image_tag_mutability = "MUTABLE"
  force_delete         = var.environment != "prod"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = { Name = "${var.app_name}-api" }
}

resource "aws_ecr_repository" "web" {
  name                 = "${var.app_name}/web"
  image_tag_mutability = "MUTABLE"
  force_delete         = var.environment != "prod"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = { Name = "${var.app_name}-web" }
}

resource "aws_ecr_repository" "worker" {
  name                 = "${var.app_name}/worker"
  image_tag_mutability = "MUTABLE"
  force_delete         = var.environment != "prod"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = { Name = "${var.app_name}-worker" }
}

# Lifecycle Policy — mirrors the daily `acr purge` task in az/acr.tf: keep the
# two newest images per repository and drop untagged manifests. CI tags with the
# full commit SHA (`github.sha`), so "two newest" is the last two deploys.
# Untagged goes first: an "any" rule must hold the highest rulePriority, because
# ECR stops evaluating a rule set once an image matches.
locals {
  ecr_lifecycle_policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Expire untagged images after 1 day"
        selection = {
          tagStatus   = "untagged"
          countType   = "sinceImagePushed"
          countUnit   = "days"
          countNumber = 1
        }
        action = { type = "expire" }
      },
      {
        rulePriority = 2
        description  = "Keep last 2 images"
        selection = {
          tagStatus   = "any"
          countType   = "imageCountMoreThan"
          countNumber = 2
        }
        action = { type = "expire" }
      },
    ]
  })
}

resource "aws_ecr_lifecycle_policy" "api" {
  repository = aws_ecr_repository.api.name
  policy     = local.ecr_lifecycle_policy
}

resource "aws_ecr_lifecycle_policy" "web" {
  repository = aws_ecr_repository.web.name
  policy     = local.ecr_lifecycle_policy
}

resource "aws_ecr_lifecycle_policy" "worker" {
  repository = aws_ecr_repository.worker.name
  policy     = local.ecr_lifecycle_policy
}
