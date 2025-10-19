# Load Balancer Module Variables

variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
}

variable "environment" {
  description = "Environment name (staging, production, dev)"
  type        = string
  validation {
    condition     = contains(["dev", "staging", "production"], var.environment)
    error_message = "Environment must be one of: dev, staging, production"
  }
}

variable "region" {
  description = "GCP region for resources"
  type        = string
  default     = "us-central1"
}

variable "domain" {
  description = "Domain name for the load balancer (e.g., staging.adyela.care)"
  type        = string
}

variable "cloud_run_service_name" {
  description = "Name of the Cloud Run web service to connect to"
  type        = string
}

variable "api_service_name" {
  description = "Name of the Cloud Run API service to connect to"
  type        = string
}

variable "patient_service_name" {
  description = "Name of the Cloud Run patient app service (Flutter web)"
  type        = string
  default     = null
}

variable "professional_service_name" {
  description = "Name of the Cloud Run professional app service (Flutter web)"
  type        = string
  default     = null
}

variable "microservices" {
  description = "Map of microservice names to Cloud Run service names for path-based routing"
  type = map(object({
    service_name = string
    path_prefix  = string
  }))
  default = {}
  # Example:
  # {
  #   "auth" = {
  #     service_name = "api-auth-staging"
  #     path_prefix  = "/auth"
  #   }
  # }
}

variable "iap_enabled" {
  description = "Enable Identity-Aware Proxy for authentication"
  type        = bool
  default     = true
}

variable "enable_cdn" {
  description = "Enable Cloud CDN for static assets"
  type        = bool
  default     = true
}

variable "ssl_certificate_domains" {
  description = "Additional domains for SSL certificate (beyond primary domain and api subdomain)"
  type        = list(string)
  default     = []
}

variable "labels" {
  description = "Labels to apply to all resources"
  type        = map(string)
  default     = {}
}
