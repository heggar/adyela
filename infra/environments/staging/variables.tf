variable "project_id" {
  description = "GCP Project ID for staging environment"
  type        = string
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  default     = "adyela"
}

variable "region" {
  description = "GCP region for resources"
  type        = string
  default     = "us-central1"
}

variable "alert_email" {
  description = "Email address for monitoring alerts"
  type        = string
  default     = "hever_gonzalezg@adyela.care"
}
