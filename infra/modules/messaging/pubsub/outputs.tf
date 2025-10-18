output "appointments_topic_id" {
  description = "ID of the appointments topic"
  value       = google_pubsub_topic.appointments.id
}

output "appointments_topic_name" {
  description = "Name of the appointments topic"
  value       = google_pubsub_topic.appointments.name
}

output "notifications_topic_id" {
  description = "ID of the notifications topic"
  value       = google_pubsub_topic.notifications.id
}

output "notifications_topic_name" {
  description = "Name of the notifications topic"
  value       = google_pubsub_topic.notifications.name
}

output "payments_topic_id" {
  description = "ID of the payments topic"
  value       = google_pubsub_topic.payments.id
}

output "payments_topic_name" {
  description = "Name of the payments topic"
  value       = google_pubsub_topic.payments.name
}

output "analytics_topic_id" {
  description = "ID of the analytics topic"
  value       = google_pubsub_topic.analytics.id
}

output "analytics_topic_name" {
  description = "Name of the analytics topic"
  value       = google_pubsub_topic.analytics.name
}

output "dead_letter_topic_id" {
  description = "ID of the dead letter topic"
  value       = google_pubsub_topic.dead_letter.id
}

output "dead_letter_topic_name" {
  description = "Name of the dead letter topic"
  value       = google_pubsub_topic.dead_letter.name
}
