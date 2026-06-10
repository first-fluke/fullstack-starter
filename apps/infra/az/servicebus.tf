# Service Bus: tasks topic + priority-filtered subscriptions
# (mirrors the AWS SNS -> SQS fan-out in aws/sns.tf + aws/sqs.tf)
resource "azurerm_servicebus_namespace" "main" {
  name                = "${local.name_prefix}-${local.unique_suffix}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  sku                 = var.servicebus_sku

  tags = local.common_tags
}

resource "azurerm_servicebus_topic" "tasks" {
  name         = "tasks"
  namespace_id = azurerm_servicebus_namespace.main.id
}

# Subscriptions route by the "priority" application property: "high" / "low"
# go to the matching subscription, everything else (including messages
# without the property) goes to default. Dead-lettering is built in:
# after max_delivery_count failed deliveries a message lands in the
# subscription's DLQ (mirrors the SQS redrive policy maxReceiveCount).
resource "azurerm_servicebus_subscription" "tasks" {
  for_each = toset(local.subscription_names)

  name               = each.key
  topic_id           = azurerm_servicebus_topic.tasks.id
  max_delivery_count = 5

  dead_lettering_on_message_expiration = true
}

# Replace the catch-all $Default rule with a SQL filter per subscription
resource "azurerm_servicebus_subscription_rule" "priority" {
  for_each = toset(local.subscription_names)

  name            = "priority-filter"
  subscription_id = azurerm_servicebus_subscription.tasks[each.key].id
  filter_type     = "SqlFilter"
  sql_filter      = local.subscription_sql_filters[each.key]
}

# Connection string for the worker's KEDA azure-servicebus scaler.
# KEDA needs Manage rights to read the subscription message count.
resource "azurerm_servicebus_namespace_authorization_rule" "worker" {
  name         = "worker-keda"
  namespace_id = azurerm_servicebus_namespace.main.id

  listen = true
  send   = true
  manage = true
}
