output "service_name" {
  description = "Name of the Cloud Run service"
  value       = google_cloud_run_v2_service.api_auth.name
}

output "service_url" {
  description = "URL of the Cloud Run service"
  value       = google_cloud_run_v2_service.api_auth.uri
}

output "service_id" {
  description = "ID of the Cloud Run service"
  value       = google_cloud_run_v2_service.api_auth.id
}

output "service_location" {
  description = "Location of the Cloud Run service"
  value       = google_cloud_run_v2_service.api_auth.location
}
