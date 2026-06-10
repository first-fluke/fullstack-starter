# ECS Autoscaling (API service, CPU-based)
resource "aws_appautoscaling_target" "api" {
  count = var.enable_autoscaling ? 1 : 0

  max_capacity       = var.api_autoscale_max
  min_capacity       = var.api_autoscale_min
  resource_id        = "service/${aws_ecs_cluster.main.name}/${aws_ecs_service.api.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "api_cpu" {
  count = var.enable_autoscaling ? 1 : 0

  name               = "${local.name_prefix}-api-cpu"
  policy_type        = "TargetTrackingScaling"
  resource_id        = one(aws_appautoscaling_target.api[*].resource_id)
  scalable_dimension = one(aws_appautoscaling_target.api[*].scalable_dimension)
  service_namespace  = one(aws_appautoscaling_target.api[*].service_namespace)

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }

    target_value       = 70.0
    scale_in_cooldown  = 300
    scale_out_cooldown = 60
  }
}

# ECS Autoscaling (Worker service, SQS queue-depth based)
resource "aws_appautoscaling_target" "worker" {
  count = var.enable_autoscaling ? 1 : 0

  max_capacity       = var.worker_autoscale_max
  min_capacity       = var.worker_autoscale_min
  resource_id        = "service/${aws_ecs_cluster.main.name}/${aws_ecs_service.worker.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "worker_queue_depth" {
  count = var.enable_autoscaling ? 1 : 0

  name               = "${local.name_prefix}-worker-queue-depth"
  policy_type        = "TargetTrackingScaling"
  resource_id        = one(aws_appautoscaling_target.worker[*].resource_id)
  scalable_dimension = one(aws_appautoscaling_target.worker[*].scalable_dimension)
  service_namespace  = one(aws_appautoscaling_target.worker[*].service_namespace)

  target_tracking_scaling_policy_configuration {
    customized_metric_specification {
      metric_name = "ApproximateNumberOfMessagesVisible"
      namespace   = "AWS/SQS"
      statistic   = "Average"

      dimensions {
        name  = "QueueName"
        value = aws_sqs_queue.main["default"].name
      }
    }

    target_value       = var.worker_queue_depth_target
    scale_in_cooldown  = 300
    scale_out_cooldown = 60
  }
}
