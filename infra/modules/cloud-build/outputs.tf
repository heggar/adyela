# Cloud Build Module Outputs

output "trigger_id" {
  description = "The ID of the Cloud Build trigger"
  value       = google_cloudbuild_trigger.trigger.trigger_id
}

output "trigger_name" {
  description = "The name of the Cloud Build trigger"
  value       = google_cloudbuild_trigger.trigger.name
}

output "trigger_location" {
  description = "The location of the Cloud Build trigger"
  value       = google_cloudbuild_trigger.trigger.location
}

output "service_account_email" {
  description = "Email of the Cloud Build service account (if created)"
  value       = var.create_service_account ? google_service_account.cloudbuild[0].email : var.service_account_email
}

output "service_account_id" {
  description = "ID of the Cloud Build service account (if created)"
  value       = var.create_service_account ? google_service_account.cloudbuild[0].account_id : null
}

output "service_account_unique_id" {
  description = "Unique ID of the Cloud Build service account (if created)"
  value       = var.create_service_account ? google_service_account.cloudbuild[0].unique_id : null
}
