variable "project_id" {
  description = "GCP Project ID for staging environment"
  type        = string
}

variable "region" {
  description = "GCP region for resources"
  type        = string
  default     = "us-central1"
}
