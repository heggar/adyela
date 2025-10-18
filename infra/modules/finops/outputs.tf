output "budget_id" {
  description = "ID of the billing budget"
  value       = var.environment == "staging" ? google_billing_budget.staging[0].id : google_billing_budget.production[0].id
}

output "budget_alert_topic_id" {
  description = "ID of the budget alerts Pub/Sub topic"
  value       = google_pubsub_topic.budget_alerts.id
}

output "budget_alert_topic_name" {
  description = "Name of the budget alerts Pub/Sub topic"
  value       = google_pubsub_topic.budget_alerts.name
}

output "notification_channel_ids" {
  description = "IDs of created notification channels"
  value       = [for channel in google_monitoring_notification_channel.email : channel.id]
}
