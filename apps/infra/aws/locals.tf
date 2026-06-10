locals {
  name_prefix = "${var.app_name}-${var.environment}"

  # SQS queues mirror the GCP Cloud Tasks queue tiers (cloudtasks.tf)
  queue_names = ["default", "high-priority", "low-priority"]

  api_url = var.domain != "" ? "https://${var.api_subdomain}.${var.domain}" : "http://${aws_lb.main.dns_name}"
  web_url = var.domain != "" ? "https://${var.domain}" : "http://${aws_lb.main.dns_name}"
}
