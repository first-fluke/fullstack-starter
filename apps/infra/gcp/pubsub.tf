# Dead Letter Topic
resource "google_pubsub_topic" "dead_letter" {
  name = "${local.name_prefix}-dead-letter"

  message_retention_duration = "604800s" # 7 days

  labels = local.labels
}

# Main Topic for async tasks
resource "google_pubsub_topic" "main" {
  name = "${local.name_prefix}-tasks"

  message_retention_duration = "86400s" # 1 day

  labels = local.labels
}

# Push Subscription to Worker
resource "google_pubsub_subscription" "worker" {
  name  = "${local.name_prefix}-worker-sub"
  topic = google_pubsub_topic.main.id

  ack_deadline_seconds       = 60
  message_retention_duration = "86400s"

  push_config {
    push_endpoint = "${google_cloud_run_v2_service.worker.uri}/tasks/pubsub"

    oidc_token {
      service_account_email = google_service_account.pubsub.email
    }
  }

  retry_policy {
    minimum_backoff = "10s"
    maximum_backoff = "600s"
  }

  dead_letter_policy {
    dead_letter_topic     = google_pubsub_topic.dead_letter.id
    max_delivery_attempts = 5
  }

  expiration_policy {
    ttl = ""
  }

  labels = local.labels
}

# Dead Letter Subscription (for monitoring/debugging)
resource "google_pubsub_subscription" "dead_letter" {
  name  = "${local.name_prefix}-dead-letter-sub"
  topic = google_pubsub_topic.dead_letter.id

  ack_deadline_seconds       = 60
  message_retention_duration = "604800s"

  expiration_policy {
    ttl = ""
  }

  labels = local.labels
}

# Allow Pub/Sub service account to publish to dead letter topic
resource "google_pubsub_topic_iam_member" "dead_letter_publisher" {
  topic  = google_pubsub_topic.dead_letter.id
  role   = "roles/pubsub.publisher"
  member = "serviceAccount:service-${data.google_project.current.number}@gcp-sa-pubsub.iam.gserviceaccount.com"
}

# Allow Pub/Sub service account to subscribe
resource "google_pubsub_subscription_iam_member" "worker_subscriber" {
  subscription = google_pubsub_subscription.worker.id
  role         = "roles/pubsub.subscriber"
  member       = "serviceAccount:service-${data.google_project.current.number}@gcp-sa-pubsub.iam.gserviceaccount.com"
}
