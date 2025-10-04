variable "project_id" {
  description = "GCP Project ID for production environment"
  type        = string
}

variable "region" {
  description = "GCP region for resources"
  type        = string
  default     = "us-central1"
}
