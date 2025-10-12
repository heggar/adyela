# Load Balancer Module Outputs

output "load_balancer_ip" {
  description = "Global IP address of the load balancer"
  value       = google_compute_global_address.lb_ip.address
}

output "load_balancer_ip_name" {
  description = "Name of the global IP address resource"
  value       = google_compute_global_address.lb_ip.name
}

output "ssl_certificate_name" {
  description = "Name of the managed SSL certificate"
  value       = google_compute_managed_ssl_certificate.web_ssl_cert.name
}

output "backend_service_name" {
  description = "Name of the backend service"
  value       = google_compute_backend_service.web_backend.name
}

output "url_map_name" {
  description = "Name of the URL map"
  value       = google_compute_url_map.web_url_map.name
}

output "https_proxy_name" {
  description = "Name of the HTTPS proxy"
  value       = google_compute_target_https_proxy.web_https_proxy.name
}

output "iap_enabled" {
  description = "Whether IAP is enabled on the backend service"
  value       = var.iap_enabled
}

output "domain" {
  description = "Domain configured for the load balancer"
  value       = var.domain
}

output "static_bucket_name" {
  description = "Name of the Cloud Storage bucket for static assets"
  value       = google_storage_bucket.static_assets.name
}

output "static_bucket_url" {
  description = "URL of the Cloud Storage bucket for static assets"
  value       = google_storage_bucket.static_assets.url
}

output "cdn_backend_bucket_name" {
  description = "Name of the CDN backend bucket"
  value       = google_compute_backend_bucket.static_backend.name
}
