# SNS Tasks Topic (mirrors GCP Pub/Sub main topic)
resource "aws_sns_topic" "tasks" {
  name              = "${local.name_prefix}-tasks"
  kms_master_key_id = "alias/aws/sns"

  tags = { Name = "${local.name_prefix}-tasks" }
}

# SNS -> SQS Subscriptions
# Messages route by the "priority" message attribute: "high" / "low" go to the
# matching queue, everything else (including messages without the attribute)
# goes to the default queue.
resource "aws_sns_topic_subscription" "tasks" {
  for_each  = toset(local.queue_names)
  topic_arn = aws_sns_topic.tasks.arn
  protocol  = "sqs"
  endpoint  = aws_sqs_queue.main[each.key].arn

  filter_policy = (
    each.key == "default"
    ? jsonencode({ priority = [{ exists = false }, "default"] })
    : jsonencode({ priority = [each.key == "high-priority" ? "high" : "low"] })
  )

  raw_message_delivery = false
}

# SQS Policy: Allow SNS to send messages
resource "aws_sqs_queue_policy" "sns_to_sqs" {
  for_each  = toset(local.queue_names)
  queue_url = aws_sqs_queue.main[each.key].url

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "sns.amazonaws.com" }
      Action    = "sqs:SendMessage"
      Resource  = aws_sqs_queue.main[each.key].arn
      Condition = {
        ArnEquals = {
          "aws:SourceArn" = aws_sns_topic.tasks.arn
        }
      }
    }]
  })
}
