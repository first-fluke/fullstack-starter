# SQS Queues (mirrors GCP Cloud Tasks queue tiers: default / high-priority / low-priority)

# Dead Letter Queues
resource "aws_sqs_queue" "dlq" {
  for_each = toset(local.queue_names)
  name     = "${local.name_prefix}-${each.key}-dlq"

  message_retention_seconds = 1209600 # 14 days
  sqs_managed_sse_enabled   = true

  tags = { Name = "${local.name_prefix}-${each.key}-dlq" }
}

# Main Queues
resource "aws_sqs_queue" "main" {
  for_each = toset(local.queue_names)
  name     = "${local.name_prefix}-${each.key}"

  visibility_timeout_seconds = 300    # 5 minutes
  message_retention_seconds  = 345600 # 4 days
  receive_wait_time_seconds  = 20     # Long polling
  sqs_managed_sse_enabled    = true

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dlq[each.key].arn
    maxReceiveCount     = 5
  })

  tags = { Name = "${local.name_prefix}-${each.key}" }
}
