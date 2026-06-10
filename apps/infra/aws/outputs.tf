output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

output "ecs_cluster_name" {
  description = "ECS cluster name"
  value       = aws_ecs_cluster.main.name
}

output "alb_dns_name" {
  description = "ALB DNS name"
  value       = aws_lb.main.dns_name
}

output "api_url" {
  description = "API base URL"
  value       = local.api_url
}

output "web_url" {
  description = "Web base URL"
  value       = local.web_url
}

output "ecr_api_url" {
  description = "ECR API repository URL"
  value       = aws_ecr_repository.api.repository_url
}

output "ecr_web_url" {
  description = "ECR Web repository URL"
  value       = aws_ecr_repository.web.repository_url
}

output "ecr_worker_url" {
  description = "ECR Worker repository URL"
  value       = aws_ecr_repository.worker.repository_url
}

output "github_actions_role_arn" {
  description = "IAM role ARN for GitHub Actions OIDC"
  value       = aws_iam_role.github_actions.arn
}

output "db_endpoint" {
  description = "Aurora cluster endpoint"
  value       = aws_rds_cluster.main.endpoint
  sensitive   = true
}

output "redis_endpoint" {
  description = "ElastiCache Redis primary endpoint"
  value       = aws_elasticache_replication_group.main.primary_endpoint_address
  sensitive   = true
}

output "uploads_bucket" {
  description = "Uploads S3 bucket name"
  value       = aws_s3_bucket.uploads.bucket
}

output "static_bucket" {
  description = "Static assets S3 bucket name"
  value       = aws_s3_bucket.static.bucket
}

output "cdn_domain" {
  description = "CloudFront distribution domain"
  value       = aws_cloudfront_distribution.static.domain_name
}

output "sns_tasks_topic_arn" {
  description = "SNS tasks topic ARN"
  value       = aws_sns_topic.tasks.arn
}

output "sqs_queue_urls" {
  description = "SQS queue URLs by name"
  value       = { for name in local.queue_names : name => aws_sqs_queue.main[name].url }
}

output "ses_verification_token" {
  description = "SES domain verification token (publish as TXT record)"
  value       = var.ses_domain != "" ? aws_ses_domain_identity.main[0].verification_token : null
}

output "ses_dkim_tokens" {
  description = "SES DKIM tokens (publish as CNAME records)"
  value       = var.ses_domain != "" ? aws_ses_domain_dkim.main[0].dkim_tokens : null
}
