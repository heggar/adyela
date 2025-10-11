# Service Account Module Outputs

output "service_account_email" {
  description = "Email of the HIPAA service account"
  value       = google_service_account.hipaa.email
}

output "service_account_id" {
  description = "ID of the HIPAA service account"
  value       = google_service_account.hipaa.id
}

output "service_account_name" {
  description = "Name of the HIPAA service account"
  value       = google_service_account.hipaa.name
}

output "service_account_unique_id" {
  description = "Unique ID of the HIPAA service account"
  value       = google_service_account.hipaa.unique_id
}
