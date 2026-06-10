# OCI Monitoring (mirrors aws/monitoring.tf CloudWatch alarms)

# Warn if monitoring is enabled in prod but no alarm_email is set
check "prod_alarm_email" {
  assert {
    condition     = !(var.environment == "prod" && var.enable_monitoring && var.alarm_email == "")
    error_message = "WARNING: alarm_email is empty in prod — alarms have no subscriber."
  }
}

# ONS Topic for alarms (SNS alarm topic equivalent)
resource "oci_ons_notification_topic" "alarms" {
  count = var.enable_monitoring ? 1 : 0

  compartment_id = oci_identity_compartment.main.id
  name           = "${local.name_prefix}-alarms"
  description    = "Alarm notifications for ${local.name_prefix}"

  freeform_tags = local.common_tags
}

# Email subscription (optional)
resource "oci_ons_subscription" "alarm_email" {
  count = var.enable_monitoring && var.alarm_email != "" ? 1 : 0

  compartment_id = oci_identity_compartment.main.id
  topic_id       = one(oci_ons_notification_topic.alarms[*].id)
  protocol       = "EMAIL"
  endpoint       = var.alarm_email

  freeform_tags = local.common_tags
}

# LB 5xx errors (aws alb_5xx_high parity: > 10 over 5 minutes)
resource "oci_monitoring_alarm" "lb_5xx_high" {
  count = var.enable_monitoring ? 1 : 0

  compartment_id        = oci_identity_compartment.main.id
  metric_compartment_id = oci_identity_compartment.main.id
  display_name          = "${local.name_prefix}-lb-5xx-high"
  is_enabled            = true
  severity              = "CRITICAL"

  namespace = "oci_lbaas"
  query     = "HttpResponses5xx[5m]{lbOcid = \"${oci_load_balancer_load_balancer.main.id}\"}.sum() > 10"

  pending_duration = "PT5M"
  destinations     = [one(oci_ons_notification_topic.alarms[*].id)]

  body                             = "Load balancer 5xx responses exceed 10 sustained over 5 minutes"
  message_format                   = "ONS_OPTIMIZED"
  metric_compartment_id_in_subtree = false

  freeform_tags = local.common_tags
}

# PostgreSQL CPU (aws rds_high_cpu parity: > 80%)
resource "oci_monitoring_alarm" "postgres_high_cpu" {
  count = var.enable_monitoring ? 1 : 0

  compartment_id        = oci_identity_compartment.main.id
  metric_compartment_id = oci_identity_compartment.main.id
  display_name          = "${local.name_prefix}-postgres-high-cpu"
  is_enabled            = true
  severity              = "WARNING"

  namespace = "oci_postgresql"
  query     = "CpuUtilization[5m]{resourceId = \"${oci_psql_db_system.main.id}\"}.mean() > 80"

  pending_duration = "PT5M"
  destinations     = [one(oci_ons_notification_topic.alarms[*].id)]

  body                             = "PostgreSQL DB system CPU utilization exceeds 80%"
  message_format                   = "ONS_OPTIMIZED"
  metric_compartment_id_in_subtree = false

  freeform_tags = local.common_tags
}
