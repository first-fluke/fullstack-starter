# Cloud Tasks Queue
resource "google_cloud_tasks_queue" "main" {
  name     = "${local.name_prefix}-queue"
  location = var.region

  rate_limits {
    max_dispatches_per_second = 100
    max_concurrent_dispatches = 10
  }

  retry_config {
    max_attempts       = 5
    max_retry_duration = "3600s"
    min_backoff        = "10s"
    max_backoff        = "300s"
    max_doublings      = 4
  }

  stackdriver_logging_config {
    sampling_ratio = 1.0
  }
}

# High Priority Queue
resource "google_cloud_tasks_queue" "high_priority" {
  name     = "${local.name_prefix}-high-priority"
  location = var.region

  rate_limits {
    max_dispatches_per_second = 500
    max_concurrent_dispatches = 50
  }

  retry_config {
    max_attempts       = 3
    max_retry_duration = "1800s"
    min_backoff        = "5s"
    max_backoff        = "60s"
    max_doublings      = 3
  }

  stackdriver_logging_config {
    sampling_ratio = 1.0
  }
}

# Low Priority Queue (for batch jobs)
resource "google_cloud_tasks_queue" "low_priority" {
  name     = "${local.name_prefix}-low-priority"
  location = var.region

  rate_limits {
    max_dispatches_per_second = 10
    max_concurrent_dispatches = 3
  }

  retry_config {
    max_attempts       = 10
    max_retry_duration = "86400s"
    min_backoff        = "60s"
    max_backoff        = "3600s"
    max_doublings      = 5
  }

  stackdriver_logging_config {
    sampling_ratio = 0.1
  }
}
