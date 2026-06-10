# Cloud Scheduler -> Pub/Sub tasks topic -> worker
# Scheduled jobs belong here, not in in-worker cron loops: with N worker
# instances an in-process cron fires N times, while a schedule publishing to
# the topic is delivered once through the push subscription.
#
# Example tfvars:
#   schedules = {
#     daily-report = {
#       schedule_expression = "0 3 * * *"
#       payload             = "{\"task\":\"daily_report\"}"
#     }
#   }

resource "google_cloud_scheduler_job" "main" {
  for_each = var.schedules

  name      = "${local.name_prefix}-${each.key}"
  region    = var.region
  schedule  = each.value.schedule_expression
  time_zone = "Etc/UTC"

  pubsub_target {
    topic_name = google_pubsub_topic.main.id
    data       = base64encode(each.value.payload)
  }
}
