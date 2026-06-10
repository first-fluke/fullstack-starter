# Scheduled jobs — NOT IMPLEMENTED on OCI (documented gap, see README Notes).
#
# The other stacks publish cron ticks as queue/topic messages so each tick is
# consumed exactly once across worker replicas:
#   aws: EventBridge Scheduler -> SNS -> SQS   (aws/scheduler.tf)
#   gcp: Cloud Scheduler -> Pub/Sub            (gcp/scheduler.tf)
#   az:  Container Apps Jobs cron              (az/scheduler.tf)
#
# OCI has no equivalent "cron -> message with payload" service as of 2026:
#   - Resource Scheduler only performs lifecycle actions (start/stop) and can
#     trigger OCI Functions on a cron — but passes NO payload to the function.
#   - Connector Hub moves events between services but has no time trigger.
#   - The least-bad native chain would be Resource Scheduler -> OCI Functions
#     (a function per schedule that hardcodes its payload) -> Queue, which
#     drags an entire Functions application + per-schedule images into the
#     stack for what is one EventBridge resource on AWS.
#
# The `schedules` variable is therefore a validated no-op placeholder kept
# for tfvars parity across stacks. If you need schedules on OCI today:
#   1. (native) build the Resource Scheduler -> Functions -> Queue chain, or
#   2. (pragmatic) run a single-replica "scheduler" container instance whose
#      only job is publishing cron ticks to the default queue — single
#      publisher, so the exactly-once property still holds.

check "schedules_not_supported" {
  assert {
    condition     = length(var.schedules) == 0
    error_message = "WARNING: var.schedules is set but OCI has no cron->queue scheduler — entries are a no-op. See scheduler.tf for alternatives."
  }
}
