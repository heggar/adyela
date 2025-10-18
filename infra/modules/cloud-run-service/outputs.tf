output "service_name" {
  description = "Name of the Cloud Run service"
  value       = google_cloud_run_v2_service.service.name
}

output "service_url" {
  description = "URL of the Cloud Run service"
  value       = google_cloud_run_v2_service.service.uri
}

output "service_id" {
  description = "ID of the Cloud Run service"
  value       = google_cloud_run_v2_service.service.id
}

output "service_location" {
  description = "Location of the Cloud Run service"
  value       = google_cloud_run_v2_service.service.location
}

output "service_account_email" {
  description = "Email of the service account created (if any)"
  value       = var.create_service_account ? google_service_account.service[0].email : var.service_account_email
}

output "service_account_id" {
  description = "ID of the service account created (if any)"
  value       = var.create_service_account ? google_service_account.service[0].id : null
}
