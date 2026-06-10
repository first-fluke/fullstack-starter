# Container Instances (mirror aws/ecs.tf services).
#
# OCI Container Instances have NO autoscaling and NO rolling deploys — each
# instance is a fixed-size unit. Scale by raising api_count / web_count /
# worker_count; deploy new images by restarting (image tag "latest" is
# re-pulled on restart) or recreating instances. See README Notes.

locals {
  availability_domain = data.oci_identity_availability_domains.main.availability_domains[0].name

  # Shared backend environment (api + worker), mirrors aws/ecs.tf
  # backend_environment (OCI env vars are a map, not a name/value list)
  backend_environment = {
    ENVIRONMENT   = var.environment
    OCI_REGION    = var.region
    DATABASE_HOST = oci_psql_db_system.main.network_details[0].primary_db_endpoint_private_ip
    # Read scaling guide: add when read replicas are enabled (see postgres.tf)
    # DATABASE_READ_HOST = <reader endpoint>
    DATABASE_NAME     = var.db_name
    DATABASE_USER     = var.db_user
    DATABASE_PASSWORD = var.DATABASE_PASSWORD
    REDIS_HOST        = oci_redis_redis_cluster.main.primary_fqdn
    REDIS_PORT        = "6379"
    REDIS_TLS         = "true"
    STORAGE_BUCKET    = oci_objectstorage_bucket.uploads.name
    STORAGE_NAMESPACE = local.namespace
    QUEUE_IDS = jsonencode({
      for name in local.queue_names : name => oci_queue_queue.main[name].id
    })
    QUEUE_MESSAGES_ENDPOINT = oci_queue_queue.main["default"].messages_endpoint
  }
}

# API
resource "oci_container_instances_container_instance" "api" {
  count = var.api_count

  compartment_id      = oci_identity_compartment.main.id
  availability_domain = local.availability_domain
  display_name        = "${local.name_prefix}-api-${count.index}"

  shape = var.container_shape
  shape_config {
    ocpus         = var.api_ocpus
    memory_in_gbs = var.api_memory_in_gbs
  }

  container_restart_policy = "ALWAYS"

  containers {
    display_name = "api"
    image_url    = local.api_image

    environment_variables = merge(local.backend_environment, {
      JWT_SECRET = var.JWT_SECRET
      API_URL    = local.api_url
    })

    health_checks {
      health_check_type        = "HTTP"
      port                     = 8000
      path                     = "/health"
      interval_in_seconds      = 30
      timeout_in_seconds       = 5
      failure_threshold        = 3
      initial_delay_in_seconds = 60
      failure_action           = "KILL"
    }
  }

  vnics {
    subnet_id             = oci_core_subnet.private.id
    nsg_ids               = [oci_core_network_security_group.apps.id]
    is_public_ip_assigned = false
  }

  freeform_tags = local.common_tags
}

# Web
resource "oci_container_instances_container_instance" "web" {
  count = var.web_count

  compartment_id      = oci_identity_compartment.main.id
  availability_domain = local.availability_domain
  display_name        = "${local.name_prefix}-web-${count.index}"

  shape = var.container_shape
  shape_config {
    ocpus         = var.web_ocpus
    memory_in_gbs = var.web_memory_in_gbs
  }

  container_restart_policy = "ALWAYS"

  containers {
    display_name = "web"
    image_url    = local.web_image

    environment_variables = {
      ENVIRONMENT          = var.environment
      NEXT_PUBLIC_API_URL  = local.api_url
      BETTER_AUTH_SECRET   = var.BETTER_AUTH_SECRET
      BETTER_AUTH_URL      = local.web_url
      GOOGLE_CLIENT_ID     = var.GOOGLE_CLIENT_ID
      GOOGLE_CLIENT_SECRET = var.GOOGLE_CLIENT_SECRET
      GITHUB_CLIENT_ID     = var.GITHUB_CLIENT_ID
      GITHUB_CLIENT_SECRET = var.GITHUB_CLIENT_SECRET
      KAKAO_CLIENT_ID      = var.KAKAO_CLIENT_ID
      KAKAO_CLIENT_SECRET  = var.KAKAO_CLIENT_SECRET
    }

    health_checks {
      health_check_type        = "HTTP"
      port                     = 3000
      path                     = "/api/health"
      interval_in_seconds      = 30
      timeout_in_seconds       = 5
      failure_threshold        = 3
      initial_delay_in_seconds = 60
      failure_action           = "KILL"
    }
  }

  vnics {
    subnet_id             = oci_core_subnet.private.id
    nsg_ids               = [oci_core_network_security_group.apps.id]
    is_public_ip_assigned = false
  }

  freeform_tags = local.common_tags
}

# Worker (no ingress — consumes queues)
resource "oci_container_instances_container_instance" "worker" {
  count = var.worker_count

  compartment_id      = oci_identity_compartment.main.id
  availability_domain = local.availability_domain
  display_name        = "${local.name_prefix}-worker-${count.index}"

  shape = var.container_shape
  shape_config {
    ocpus         = var.worker_ocpus
    memory_in_gbs = var.worker_memory_in_gbs
  }

  container_restart_policy = "ALWAYS"

  containers {
    display_name = "worker"
    image_url    = local.worker_image

    environment_variables = merge(local.backend_environment, {
      OPENAI_API_KEY    = var.OPENAI_API_KEY
      ANTHROPIC_API_KEY = var.ANTHROPIC_API_KEY
      GOOGLE_AI_API_KEY = var.GOOGLE_AI_API_KEY
    })
  }

  vnics {
    subnet_id             = oci_core_subnet.private.id
    nsg_ids               = [oci_core_network_security_group.apps.id]
    is_public_ip_assigned = false
  }

  freeform_tags = local.common_tags
}

# The container instance resource exports only vnic_id — resolve private IPs
# for the LB backends through the VNIC data source.
data "oci_core_vnic" "api" {
  count   = var.api_count
  vnic_id = oci_container_instances_container_instance.api[count.index].vnics[0].vnic_id
}

data "oci_core_vnic" "web" {
  count   = var.web_count
  vnic_id = oci_container_instances_container_instance.web[count.index].vnics[0].vnic_id
}
