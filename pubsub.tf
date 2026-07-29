# =====================================================================
# Pub/Sub — fully managed async messaging (topic + subscription).
# Cloud mapping:
#   Pub/Sub topic        -> AWS SNS topic / Kinesis stream | Azure Event Hubs / Service Bus topic
#   Pub/Sub subscription -> AWS SQS queue subscribed to SNS | Azure subscription
#   dead_letter_topic    -> SQS DLQ
# Model: publishers -> topic -> (many) subscriptions -> subscribers.
# One message fan-outs to every subscription (pub/sub), and within a
# subscription it's delivered to one consumer (queue semantics).
# =====================================================================

# ---- Topic (where publishers send) ----
resource "google_pubsub_topic" "events" {
  name = "${var.name_prefix}-${var.pubsub_topic_name}"

  message_retention_duration = "86400s" # 1 day

  depends_on = [google_project_service.enabled]
}

# ---- Dead-letter topic (undeliverable messages land here) ----
resource "google_pubsub_topic" "events_dlq" {
  name       = "${var.name_prefix}-${var.pubsub_topic_name}-dlq"
  depends_on = [google_project_service.enabled]
}

# ---- Subscription (a consumer's view of the topic) ----
resource "google_pubsub_subscription" "events_sub" {
  name  = "${var.name_prefix}-${var.pubsub_topic_name}-sub"
  topic = google_pubsub_topic.events.id

  # Pull subscription (consumer polls). Alternative: push_config -> HTTPS endpoint.
  ack_deadline_seconds       = 20
  message_retention_duration = "86400s"
  retain_acked_messages      = false

  # Redelivery/backoff before giving up to the DLQ.
  retry_policy {
    minimum_backoff = "10s"
    maximum_backoff = "600s"
  }

  dead_letter_policy {
    dead_letter_topic     = google_pubsub_topic.events_dlq.id
    max_delivery_attempts = 5
  }
}

output "pubsub_topic" {
  value       = google_pubsub_topic.events.name
  description = "Publish to this topic."
}

output "pubsub_subscription" {
  value       = google_pubsub_subscription.events_sub.name
  description = "Consumers pull from this subscription."
}
