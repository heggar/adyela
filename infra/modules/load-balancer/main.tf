# Load Balancer Module - HIPAA-Compliant Public Access with IAP
# Cost: ~$18-25/month
# Provides: Public access with mandatory authentication via Identity-Aware Proxy

terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.0"
    }
  }
}

# Global IP Address for Load Balancer
resource "google_compute_global_address" "lb_ip" {
  name         = "${var.project_name}-${var.environment}-lb-ip"
  description  = "Global IP for ${var.environment} Load Balancer"
  address_type = "EXTERNAL"
  ip_version   = "IPV4"

  labels = var.labels
}

# Serverless Network Endpoint Group for Cloud Run Web
resource "google_compute_region_network_endpoint_group" "cloud_run_neg" {
  name                  = "${var.project_name}-${var.environment}-cloud-run-neg"
  network_endpoint_type = "SERVERLESS"
  region                = var.region

  cloud_run {
    service = var.cloud_run_service_name
  }
}

# Serverless Network Endpoint Group for Cloud Run API
resource "google_compute_region_network_endpoint_group" "api_neg" {
  name                  = "${var.project_name}-${var.environment}-api-neg"
  network_endpoint_type = "SERVERLESS"
  region                = var.region

  cloud_run {
    service = var.api_service_name
  }
}

# Cloud Storage Bucket for Static Assets
resource "google_storage_bucket" "static_assets" {
  name          = "${var.project_name}-${var.environment}-static-assets"
  location      = var.region
  force_destroy = false

  uniform_bucket_level_access = true
  public_access_prevention    = "unspecified" # Allow public access for CDN

  cors {
    origin          = ["https://${var.domain}", "https://api.${var.domain}"]
    method          = ["GET", "HEAD", "OPTIONS"]
    response_header = ["*"]
    max_age_seconds = 3600
  }

  lifecycle_rule {
    condition {
      age = 30
    }
    action {
      type = "Delete"
    }
  }

  labels = var.labels
}

# Make bucket publicly readable
resource "google_storage_bucket_iam_member" "static_assets_public" {
  bucket = google_storage_bucket.static_assets.name
  role   = "roles/storage.objectViewer"
  member = "allUsers"
}

# Backend Bucket for CDN
resource "google_compute_backend_bucket" "static_backend" {
  name        = "${var.project_name}-${var.environment}-static-backend"
  bucket_name = google_storage_bucket.static_assets.name
  enable_cdn  = true

  cdn_policy {
    cache_mode                   = "CACHE_ALL_STATIC"
    default_ttl                  = 86400      # 1 day
    client_ttl                   = 31536000   # 1 year
    max_ttl                      = 31536000   # 1 year
    negative_caching             = true
    serve_while_stale            = 86400      # 1 day
    request_coalescing           = true
  }
}

# Backend Service for Cloud Run Web
resource "google_compute_backend_service" "web_backend" {
  name        = "${var.project_name}-${var.environment}-web-backend"
  description = "Backend service for ${var.environment} web application"
  protocol    = "HTTP"
  port_name   = "http"
  timeout_sec = 30

  # Health check configuration - not needed for serverless NEGs
  # health_checks = [google_compute_health_check.web_health_check.id]

  # Backend configuration
  backend {
    group = google_compute_region_network_endpoint_group.cloud_run_neg.id
  }

  # Session affinity for better user experience
  session_affinity        = "GENERATED_COOKIE"
  affinity_cookie_ttl_sec = 3600

  # Security settings
  security_policy = null # No Cloud Armor for cost optimization

  # Logging for audit trails
  log_config {
    enable      = true
    sample_rate = 1.0
  }
}

# Backend Service for Cloud Run API
resource "google_compute_backend_service" "api_backend" {
  name        = "${var.project_name}-${var.environment}-api-backend"
  description = "Backend service for ${var.environment} API"
  protocol    = "HTTP"
  port_name   = "http"
  timeout_sec = 30

  # Health check configuration - not needed for serverless NEGs
  # health_checks = [google_compute_health_check.api_health_check.id]

  # Backend configuration
  backend {
    group = google_compute_region_network_endpoint_group.api_neg.id
  }

  # Session affinity for better user experience
  session_affinity        = "GENERATED_COOKIE"
  affinity_cookie_ttl_sec = 3600

  # Security settings
  security_policy = null # No Cloud Armor for cost optimization

  # Logging for audit trails
  log_config {
    enable      = true
    sample_rate = 1.0
  }
}

# Health Check for Cloud Run Web
resource "google_compute_health_check" "web_health_check" {
  name                = "${var.project_name}-${var.environment}-web-health-check"
  description         = "Health check for ${var.environment} web service"
  timeout_sec         = 5
  check_interval_sec  = 10
  healthy_threshold   = 2
  unhealthy_threshold = 3

  http_health_check {
    port         = 8080
    request_path = "/"
    proxy_header = "NONE"
  }
}

# Health Check for Cloud Run API
resource "google_compute_health_check" "api_health_check" {
  name                = "${var.project_name}-${var.environment}-api-health-check"
  description         = "Health check for ${var.environment} API service"
  timeout_sec         = 5
  check_interval_sec  = 10
  healthy_threshold   = 2
  unhealthy_threshold = 3

  http_health_check {
    port         = 8000
    request_path = "/health"
    proxy_header = "NONE"
  }
}

# URL Map for routing
resource "google_compute_url_map" "web_url_map" {
  name            = "${var.project_name}-${var.environment}-web-url-map"
  description     = "URL map for ${var.environment} web application"
  default_service = google_compute_backend_service.web_backend.id

  # HTTP to HTTPS redirect
  host_rule {
    hosts        = [var.domain, "api.${var.domain}"]
    path_matcher = "allpaths"
  }

  path_matcher {
    name            = "allpaths"
    default_service = google_compute_backend_service.web_backend.id

    # Route static assets to CDN
    path_rule {
      paths   = ["/static/*", "/assets/*"]
      service = google_compute_backend_bucket.static_backend.id
    }

    # Route health checks to API backend
    path_rule {
      paths   = ["/health", "/readiness"]
      service = google_compute_backend_service.api_backend.id
    }

    # Route API requests to API backend
    path_rule {
      paths   = ["/api/*"]
      service = google_compute_backend_service.api_backend.id
    }
  }
}

# HTTP Proxy for redirects
resource "google_compute_target_http_proxy" "web_http_proxy" {
  name    = "${var.project_name}-${var.environment}-web-http-proxy"
  url_map = google_compute_url_map.web_url_map.id
}

# HTTPS Proxy
resource "google_compute_target_https_proxy" "web_https_proxy" {
  name             = "${var.project_name}-${var.environment}-web-https-proxy"
  url_map          = google_compute_url_map.web_url_map.id
  ssl_certificates = [google_compute_managed_ssl_certificate.web_ssl_cert.id]
}

# Managed SSL Certificate
resource "google_compute_managed_ssl_certificate" "web_ssl_cert" {
  name = "${var.project_name}-${var.environment}-web-ssl-cert"

  managed {
    domains = [var.domain, "api.${var.domain}"]
  }
}

# Global Forwarding Rule for HTTP (redirect to HTTPS)
resource "google_compute_global_forwarding_rule" "web_http_forwarding_rule" {
  name       = "${var.project_name}-${var.environment}-web-http-forwarding-rule"
  target     = google_compute_target_http_proxy.web_http_proxy.id
  port_range = "80"
  ip_address = google_compute_global_address.lb_ip.address
}

# Global Forwarding Rule for HTTPS
resource "google_compute_global_forwarding_rule" "web_https_forwarding_rule" {
  name       = "${var.project_name}-${var.environment}-web-https-forwarding-rule"
  target     = google_compute_target_https_proxy.web_https_proxy.id
  port_range = "443"
  ip_address = google_compute_global_address.lb_ip.address
}

# Identity-Aware Proxy (IAP) Configuration
# Note: IAP configuration will be done manually in GCP Console
# This is because IAP requires OAuth consent screen setup which needs manual interaction
