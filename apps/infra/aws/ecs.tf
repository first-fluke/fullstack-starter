# ECS Cluster
resource "aws_ecs_cluster" "main" {
  name = local.name_prefix

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = { Name = "${local.name_prefix}-cluster" }
}

# CloudWatch Log Groups
resource "aws_cloudwatch_log_group" "api" {
  name              = "/ecs/${local.name_prefix}/api"
  retention_in_days = 30

  tags = { Name = "${local.name_prefix}-api-logs" }
}

resource "aws_cloudwatch_log_group" "web" {
  name              = "/ecs/${local.name_prefix}/web"
  retention_in_days = 30

  tags = { Name = "${local.name_prefix}-web-logs" }
}

resource "aws_cloudwatch_log_group" "worker" {
  name              = "/ecs/${local.name_prefix}/worker"
  retention_in_days = 30

  tags = { Name = "${local.name_prefix}-worker-logs" }
}

# Task Definitions
locals {
  # Shared backend environment (api + worker), mirrors GCP compute.tf env wiring
  backend_environment = [
    { name = "ENVIRONMENT", value = var.environment },
    { name = "AWS_REGION", value = var.aws_region },
    { name = "DATABASE_HOST", value = aws_rds_cluster.main.endpoint },
    # Read scaling guide: add when read replicas are enabled (see rds.tf)
    # { name = "DATABASE_READ_HOST", value = aws_rds_cluster.main.reader_endpoint },
    { name = "DATABASE_NAME", value = var.db_name },
    { name = "DATABASE_USER", value = var.db_user },
    { name = "REDIS_HOST", value = aws_elasticache_replication_group.main.primary_endpoint_address },
    { name = "REDIS_PORT", value = "6379" },
    { name = "REDIS_TLS", value = "true" },
    { name = "STORAGE_BUCKET", value = aws_s3_bucket.uploads.bucket },
    { name = "SNS_TOPIC_ARN", value = aws_sns_topic.tasks.arn },
    { name = "DATABASE_PASSWORD", value = var.DATABASE_PASSWORD },
  ]
}

resource "aws_ecs_task_definition" "api" {
  family                   = "${local.name_prefix}-api"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = var.api_cpu
  memory                   = var.api_memory
  execution_role_arn       = aws_iam_role.ecs_execution.arn
  task_role_arn            = aws_iam_role.ecs_task.arn

  container_definitions = jsonencode([{
    name  = "api"
    image = "${aws_ecr_repository.api.repository_url}:latest"

    portMappings = [{
      containerPort = 8000
      protocol      = "tcp"
    }]

    environment = concat(local.backend_environment, [
      { name = "JWT_SECRET", value = var.JWT_SECRET },
      { name = "API_URL", value = local.api_url },
    ])

    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = aws_cloudwatch_log_group.api.name
        "awslogs-region"        = var.aws_region
        "awslogs-stream-prefix" = "api"
      }
    }

    healthCheck = {
      command     = ["CMD-SHELL", "python -c \"import urllib.request; urllib.request.urlopen('http://localhost:8000/health')\" || exit 1"]
      interval    = 30
      timeout     = 5
      retries     = 3
      startPeriod = 60
    }
  }])

  tags = { Name = "${local.name_prefix}-api-task" }
}

resource "aws_ecs_task_definition" "web" {
  family                   = "${local.name_prefix}-web"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = var.web_cpu
  memory                   = var.web_memory
  execution_role_arn       = aws_iam_role.ecs_execution.arn
  task_role_arn            = aws_iam_role.ecs_task.arn

  container_definitions = jsonencode([{
    name  = "web"
    image = "${aws_ecr_repository.web.repository_url}:latest"

    portMappings = [{
      containerPort = 3000
      protocol      = "tcp"
    }]

    environment = [
      { name = "ENVIRONMENT", value = var.environment },
      { name = "NEXT_PUBLIC_API_URL", value = local.api_url },
      { name = "BETTER_AUTH_SECRET", value = var.BETTER_AUTH_SECRET },
      { name = "BETTER_AUTH_URL", value = local.web_url },
      { name = "GOOGLE_CLIENT_ID", value = var.GOOGLE_CLIENT_ID },
      { name = "GOOGLE_CLIENT_SECRET", value = var.GOOGLE_CLIENT_SECRET },
      { name = "GITHUB_CLIENT_ID", value = var.GITHUB_CLIENT_ID },
      { name = "GITHUB_CLIENT_SECRET", value = var.GITHUB_CLIENT_SECRET },
      { name = "KAKAO_CLIENT_ID", value = var.KAKAO_CLIENT_ID },
      { name = "KAKAO_CLIENT_SECRET", value = var.KAKAO_CLIENT_SECRET },
    ]

    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = aws_cloudwatch_log_group.web.name
        "awslogs-region"        = var.aws_region
        "awslogs-stream-prefix" = "web"
      }
    }
  }])

  tags = { Name = "${local.name_prefix}-web-task" }
}

resource "aws_ecs_task_definition" "worker" {
  family                   = "${local.name_prefix}-worker"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = var.worker_cpu
  memory                   = var.worker_memory
  execution_role_arn       = aws_iam_role.ecs_execution.arn
  task_role_arn            = aws_iam_role.ecs_task.arn

  container_definitions = jsonencode([{
    name  = "worker"
    image = "${aws_ecr_repository.worker.repository_url}:latest"

    environment = concat(local.backend_environment, [
      { name = "OPENAI_API_KEY", value = var.OPENAI_API_KEY },
      { name = "ANTHROPIC_API_KEY", value = var.ANTHROPIC_API_KEY },
      { name = "GOOGLE_AI_API_KEY", value = var.GOOGLE_AI_API_KEY },
      {
        name = "SQS_QUEUE_URLS"
        value = jsonencode({
          for name in local.queue_names : name => aws_sqs_queue.main[name].url
        })
      },
    ])

    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = aws_cloudwatch_log_group.worker.name
        "awslogs-region"        = var.aws_region
        "awslogs-stream-prefix" = "worker"
      }
    }
  }])

  tags = { Name = "${local.name_prefix}-worker-task" }
}

# ECS Services
resource "aws_ecs_service" "api" {
  name            = "api"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.api.arn
  desired_count   = var.api_desired_count
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = aws_subnet.private[*].id
    security_groups  = [aws_security_group.ecs.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.api.arn
    container_name   = "api"
    container_port   = 8000
  }

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  lifecycle {
    ignore_changes = [task_definition, desired_count]
  }

  tags = { Name = "${local.name_prefix}-api-svc" }
}

resource "aws_ecs_service" "web" {
  name            = "web"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.web.arn
  desired_count   = var.web_desired_count
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = aws_subnet.private[*].id
    security_groups  = [aws_security_group.ecs.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.web.arn
    container_name   = "web"
    container_port   = 3000
  }

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  lifecycle {
    ignore_changes = [task_definition, desired_count]
  }

  tags = { Name = "${local.name_prefix}-web-svc" }
}

resource "aws_ecs_service" "worker" {
  name            = "worker"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.worker.arn
  desired_count   = var.worker_desired_count
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = aws_subnet.private[*].id
    security_groups  = [aws_security_group.ecs.id]
    assign_public_ip = false
  }

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  lifecycle {
    ignore_changes = [task_definition, desired_count]
  }

  tags = { Name = "${local.name_prefix}-worker-svc" }
}
