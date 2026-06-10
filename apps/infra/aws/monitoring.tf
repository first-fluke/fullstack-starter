# CloudWatch Monitoring

# Warn if monitoring is enabled in prod but no alarm_email is set
check "prod_alarm_email" {
  assert {
    condition     = !(var.environment == "prod" && var.enable_monitoring && var.alarm_email == "")
    error_message = "WARNING: alarm_email is empty in prod — alarms have no subscriber."
  }
}

# SNS Topic for Alarms
resource "aws_sns_topic" "alarms" {
  count             = var.enable_monitoring ? 1 : 0
  name              = "${local.name_prefix}-alarms"
  kms_master_key_id = "alias/aws/sns"

  tags = { Name = "${local.name_prefix}-alarms" }
}

# SNS Email Subscription (optional)
resource "aws_sns_topic_subscription" "alarm_email" {
  count     = var.enable_monitoring && var.alarm_email != "" ? 1 : 0
  topic_arn = one(aws_sns_topic.alarms[*].arn)
  protocol  = "email"
  endpoint  = var.alarm_email
}

# CloudWatch Dashboard
resource "aws_cloudwatch_dashboard" "main" {
  count          = var.enable_monitoring ? 1 : 0
  dashboard_name = local.name_prefix

  dashboard_body = jsonencode({
    widgets = [
      # Row 1: ECS
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6
        properties = {
          title  = "ECS API - CPU Utilization"
          region = var.aws_region
          metrics = [[
            "AWS/ECS",
            "CPUUtilization",
            "ClusterName", aws_ecs_cluster.main.name,
            "ServiceName", aws_ecs_service.api.name
          ]]
          period = 60
          stat   = "Average"
          yAxis  = { left = { min = 0, max = 100 } }
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 0
        width  = 12
        height = 6
        properties = {
          title  = "ECS API - Memory Utilization"
          region = var.aws_region
          metrics = [[
            "AWS/ECS",
            "MemoryUtilization",
            "ClusterName", aws_ecs_cluster.main.name,
            "ServiceName", aws_ecs_service.api.name
          ]]
          period = 60
          stat   = "Average"
          yAxis  = { left = { min = 0, max = 100 } }
        }
      },
      # Row 2: ALB
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 8
        height = 6
        properties = {
          title  = "ALB - Request Count"
          region = var.aws_region
          metrics = [[
            "AWS/ApplicationELB",
            "RequestCount",
            "LoadBalancer", aws_lb.main.arn_suffix
          ]]
          period = 60
          stat   = "Sum"
        }
      },
      {
        type   = "metric"
        x      = 8
        y      = 6
        width  = 8
        height = 6
        properties = {
          title  = "ALB - 5XX Errors"
          region = var.aws_region
          metrics = [[
            "AWS/ApplicationELB",
            "HTTPCode_Target_5XX_Count",
            "LoadBalancer", aws_lb.main.arn_suffix
          ]]
          period = 60
          stat   = "Sum"
        }
      },
      {
        type   = "metric"
        x      = 16
        y      = 6
        width  = 8
        height = 6
        properties = {
          title  = "ALB - Target Response Time (p99)"
          region = var.aws_region
          metrics = [[
            "AWS/ApplicationELB",
            "TargetResponseTime",
            "LoadBalancer", aws_lb.main.arn_suffix
          ]]
          period = 60
          stat   = "p99"
        }
      },
      # Row 3: RDS
      {
        type   = "metric"
        x      = 0
        y      = 12
        width  = 8
        height = 6
        properties = {
          title  = "RDS - Database Connections"
          region = var.aws_region
          metrics = [[
            "AWS/RDS",
            "DatabaseConnections",
            "DBClusterIdentifier", aws_rds_cluster.main.cluster_identifier
          ]]
          period = 60
          stat   = "Average"
        }
      },
      {
        type   = "metric"
        x      = 8
        y      = 12
        width  = 8
        height = 6
        properties = {
          title  = "RDS - CPU Utilization"
          region = var.aws_region
          metrics = [[
            "AWS/RDS",
            "CPUUtilization",
            "DBClusterIdentifier", aws_rds_cluster.main.cluster_identifier
          ]]
          period = 60
          stat   = "Average"
          yAxis  = { left = { min = 0, max = 100 } }
        }
      },
      {
        type   = "metric"
        x      = 16
        y      = 12
        width  = 8
        height = 6
        properties = {
          title  = "RDS - Freeable Memory"
          region = var.aws_region
          metrics = [[
            "AWS/RDS",
            "FreeableMemory",
            "DBClusterIdentifier", aws_rds_cluster.main.cluster_identifier
          ]]
          period = 60
          stat   = "Average"
        }
      },
      # Row 4: SQS
      {
        type   = "metric"
        x      = 0
        y      = 18
        width  = 24
        height = 6
        properties = {
          title  = "SQS - Messages Visible"
          region = var.aws_region
          metrics = [for q in local.queue_names :
            ["AWS/SQS", "ApproximateNumberOfMessagesVisible", "QueueName", aws_sqs_queue.main[q].name]
          ]
          period = 60
          stat   = "Maximum"
        }
      },
    ]
  })
}

# CloudWatch Alarms
resource "aws_cloudwatch_metric_alarm" "api_high_cpu" {
  count = var.enable_monitoring ? 1 : 0

  alarm_name          = "${local.name_prefix}-api-high-cpu"
  alarm_description   = "ECS API service CPU utilization exceeds 80%"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 5
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = 60
  statistic           = "Average"
  threshold           = 80
  treat_missing_data  = "notBreaching"

  dimensions = {
    ClusterName = aws_ecs_cluster.main.name
    ServiceName = aws_ecs_service.api.name
  }

  alarm_actions = [one(aws_sns_topic.alarms[*].arn)]
  ok_actions    = [one(aws_sns_topic.alarms[*].arn)]

  tags = { Name = "${local.name_prefix}-api-high-cpu" }
}

resource "aws_cloudwatch_metric_alarm" "alb_5xx_high" {
  count = var.enable_monitoring ? 1 : 0

  alarm_name          = "${local.name_prefix}-alb-5xx-high"
  alarm_description   = "ALB 5XX error count exceeds 10 sustained over 2 periods"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "HTTPCode_Target_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = 300
  statistic           = "Sum"
  threshold           = 10
  treat_missing_data  = "notBreaching"

  dimensions = {
    LoadBalancer = aws_lb.main.arn_suffix
  }

  alarm_actions = [one(aws_sns_topic.alarms[*].arn)]
  ok_actions    = [one(aws_sns_topic.alarms[*].arn)]

  tags = { Name = "${local.name_prefix}-alb-5xx-high" }
}

resource "aws_cloudwatch_metric_alarm" "rds_high_cpu" {
  count = var.enable_monitoring ? 1 : 0

  alarm_name          = "${local.name_prefix}-rds-high-cpu"
  alarm_description   = "RDS Aurora CPU utilization exceeds 80%"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 5
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = 60
  statistic           = "Average"
  threshold           = 80
  treat_missing_data  = "notBreaching"

  dimensions = {
    DBClusterIdentifier = aws_rds_cluster.main.cluster_identifier
  }

  alarm_actions = [one(aws_sns_topic.alarms[*].arn)]
  ok_actions    = [one(aws_sns_topic.alarms[*].arn)]

  tags = { Name = "${local.name_prefix}-rds-high-cpu" }
}

resource "aws_cloudwatch_metric_alarm" "sqs_dlq_messages" {
  for_each = var.enable_monitoring ? toset(local.queue_names) : toset([])

  alarm_name          = "${local.name_prefix}-${each.key}-dlq-messages"
  alarm_description   = "DLQ ${each.key} has messages waiting — investigate consumer failures"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 5
  metric_name         = "ApproximateNumberOfMessagesVisible"
  namespace           = "AWS/SQS"
  period              = 60
  statistic           = "Maximum"
  threshold           = 0
  treat_missing_data  = "notBreaching"

  dimensions = {
    QueueName = aws_sqs_queue.dlq[each.key].name
  }

  alarm_actions = [one(aws_sns_topic.alarms[*].arn)]
  ok_actions    = [one(aws_sns_topic.alarms[*].arn)]

  tags = { Name = "${local.name_prefix}-${each.key}-dlq-messages" }
}
