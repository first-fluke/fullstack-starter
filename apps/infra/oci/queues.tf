# OCI Queues (mirror GCP Cloud Tasks queue tiers and aws/sqs.tf:
# default / high-priority / low-priority)
#
# Unlike SQS there is no separate DLQ resource — each queue has a built-in
# dead letter queue activated by dead_letter_queue_delivery_count > 0.
# Failed messages move to the DLQ after 5 deliveries (aws maxReceiveCount=5).
resource "oci_queue_queue" "main" {
  for_each = toset(local.queue_names)

  compartment_id = oci_identity_compartment.main.id
  display_name   = "${local.name_prefix}-${each.key}"

  dead_letter_queue_delivery_count = 5
  retention_in_seconds             = 345600 # 4 days (aws/sqs.tf parity)
  visibility_in_seconds            = 300    # 5 minutes
  timeout_in_seconds               = 30     # long-poll wait

  freeform_tags = local.common_tags
}
