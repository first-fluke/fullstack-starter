# EventBridge Scheduler -> SNS tasks topic -> SQS -> worker
# Scheduled jobs belong here, not in in-worker cron loops: with N worker
# tasks an in-process cron fires N times, while a schedule publishing to the
# topic is consumed exactly once by whichever worker receives the message.
#
# Example tfvars:
#   schedules = {
#     daily-report = {
#       schedule_expression = "cron(0 3 * * ? *)"
#       payload             = "{\"task\":\"daily_report\"}"
#     }
#   }

resource "aws_iam_role" "scheduler" {
  count = length(var.schedules) > 0 ? 1 : 0
  name  = "${local.name_prefix}-scheduler"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "scheduler.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy" "scheduler" {
  count = length(var.schedules) > 0 ? 1 : 0
  name  = "publish-tasks"
  role  = aws_iam_role.scheduler[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = "sns:Publish"
      Resource = aws_sns_topic.tasks.arn
    }]
  })
}

resource "aws_scheduler_schedule" "main" {
  for_each = var.schedules

  name                = "${local.name_prefix}-${each.key}"
  schedule_expression = each.value.schedule_expression

  flexible_time_window {
    mode = "OFF"
  }

  target {
    arn      = aws_sns_topic.tasks.arn
    role_arn = aws_iam_role.scheduler[0].arn
    input    = each.value.payload
  }
}
