output "api_uptime_check_id" {
  description = "ID of the API uptime check"
  value       = google_monitoring_uptime_check_config.api_health.id
}

output "web_uptime_check_id" {
  description = "ID of the web uptime check"
  value       = google_monitoring_uptime_check_config.web_homepage.id
}

output "dashboard_url" {
  description = "URL to the monitoring dashboard"
  value       = "https://console.cloud.google.com/monitoring/dashboards/custom/${google_monitoring_dashboard.main_dashboard.id}?project=${var.project_id}"
}

output "slo_name" {
  description = "Name of the SLO"
  value       = google_monitoring_slo.api_availability.name
}
