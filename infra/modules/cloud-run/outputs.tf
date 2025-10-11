# ================================================================================
# Cloud Run Module Outputs
# ================================================================================

output "api_service_name" {
  description = "Name of the API Cloud Run service"
  value       = google_cloud_run_v2_service.api.name
}

output "api_service_url" {
  description = "URL of the API Cloud Run service"
  value       = google_cloud_run_v2_service.api.uri
}

output "web_service_name" {
  description = "Name of the Web Cloud Run service"
  value       = google_cloud_run_v2_service.web.name
}

output "web_service_url" {
  description = "URL of the Web Cloud Run service"
  value       = google_cloud_run_v2_service.web.uri
}

output "api_service_id" {
  description = "ID of the API Cloud Run service"
  value       = google_cloud_run_v2_service.api.id
}

output "web_service_id" {
  description = "ID of the Web Cloud Run service"
  value       = google_cloud_run_v2_service.web.id
}
