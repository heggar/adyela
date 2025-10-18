variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "environment" {
  description = "Environment name (staging, production)"
  type        = string
}

variable "notifications_service_url" {
  description = "URL of the notifications Cloud Run service"
  type        = string
}

variable "notifications_service_account" {
  description = "Service account email for notifications service"
  type        = string
}

variable "analytics_service_url" {
  description = "URL of the analytics Cloud Run service"
  type        = string
}

variable "analytics_service_account" {
  description = "Service account email for analytics service"
  type        = string
}
