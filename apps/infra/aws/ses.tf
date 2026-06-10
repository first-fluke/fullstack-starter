# SES (optional — enabled when ses_domain is set)
# Domain verification requires publishing the returned DKIM/verification DNS
# records; see outputs ses_verification_token and ses_dkim_tokens.

resource "aws_ses_domain_identity" "main" {
  count  = var.ses_domain != "" ? 1 : 0
  domain = var.ses_domain
}

resource "aws_ses_domain_dkim" "main" {
  count  = var.ses_domain != "" ? 1 : 0
  domain = aws_ses_domain_identity.main[0].domain
}

# SNS Topics for SES Feedback
resource "aws_sns_topic" "ses_bounces" {
  count = var.ses_domain != "" ? 1 : 0
  name  = "${local.name_prefix}-ses-bounces"

  tags = { Name = "${local.name_prefix}-ses-bounces" }
}

resource "aws_sns_topic" "ses_complaints" {
  count = var.ses_domain != "" ? 1 : 0
  name  = "${local.name_prefix}-ses-complaints"

  tags = { Name = "${local.name_prefix}-ses-complaints" }
}

# SES -> SNS Notification Links
resource "aws_ses_identity_notification_topic" "bounces" {
  count                    = var.ses_domain != "" ? 1 : 0
  identity                 = aws_ses_domain_identity.main[0].domain
  notification_type        = "Bounce"
  topic_arn                = aws_sns_topic.ses_bounces[0].arn
  include_original_headers = false
}

resource "aws_ses_identity_notification_topic" "complaints" {
  count                    = var.ses_domain != "" ? 1 : 0
  identity                 = aws_ses_domain_identity.main[0].domain
  notification_type        = "Complaint"
  topic_arn                = aws_sns_topic.ses_complaints[0].arn
  include_original_headers = false
}

# SQS Queue for SES Bounce/Complaint events
resource "aws_sqs_queue" "ses_bounce_dlq" {
  count = var.ses_domain != "" ? 1 : 0
  name  = "${local.name_prefix}-ses-bounce-dlq"

  message_retention_seconds = 1209600 # 14 days
  sqs_managed_sse_enabled   = true

  tags = { Name = "${local.name_prefix}-ses-bounce-dlq" }
}

resource "aws_sqs_queue" "ses_bounce_queue" {
  count = var.ses_domain != "" ? 1 : 0
  name  = "${local.name_prefix}-ses-bounce-queue"

  visibility_timeout_seconds = 300    # 5 minutes
  message_retention_seconds  = 345600 # 4 days
  receive_wait_time_seconds  = 20     # Long polling
  sqs_managed_sse_enabled    = true

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.ses_bounce_dlq[0].arn
    maxReceiveCount     = 3
  })

  tags = { Name = "${local.name_prefix}-ses-bounce-queue" }
}

# SNS -> SQS Subscriptions
resource "aws_sns_topic_subscription" "ses_bounces_to_sqs" {
  count                = var.ses_domain != "" ? 1 : 0
  topic_arn            = aws_sns_topic.ses_bounces[0].arn
  protocol             = "sqs"
  endpoint             = aws_sqs_queue.ses_bounce_queue[0].arn
  raw_message_delivery = false
}

resource "aws_sns_topic_subscription" "ses_complaints_to_sqs" {
  count                = var.ses_domain != "" ? 1 : 0
  topic_arn            = aws_sns_topic.ses_complaints[0].arn
  protocol             = "sqs"
  endpoint             = aws_sqs_queue.ses_bounce_queue[0].arn
  raw_message_delivery = false
}

# SQS Policy: Allow both SNS topics to send to the queue
resource "aws_sqs_queue_policy" "ses_bounce_queue_policy" {
  count     = var.ses_domain != "" ? 1 : 0
  queue_url = aws_sqs_queue.ses_bounce_queue[0].url

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { Service = "sns.amazonaws.com" }
        Action    = "sqs:SendMessage"
        Resource  = aws_sqs_queue.ses_bounce_queue[0].arn
        Condition = {
          ArnEquals = {
            "aws:SourceArn" = aws_sns_topic.ses_bounces[0].arn
          }
        }
      },
      {
        Effect    = "Allow"
        Principal = { Service = "sns.amazonaws.com" }
        Action    = "sqs:SendMessage"
        Resource  = aws_sqs_queue.ses_bounce_queue[0].arn
        Condition = {
          ArnEquals = {
            "aws:SourceArn" = aws_sns_topic.ses_complaints[0].arn
          }
        }
      },
    ]
  })
}
