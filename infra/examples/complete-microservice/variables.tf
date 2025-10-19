# Variables for Complete Microservice Example

variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "region" {
  description = "GCP region for resources"
  type        = string
  default     = "us-central1"
}

variable "environment" {
  description = "Environment (staging or production)"
  type        = string

  validation {
    condition     = contains(["staging", "production"], var.environment)
    error_message = "Environment must be either 'staging' or 'production'"
  }
}

variable "github_owner" {
  description = "GitHub repository owner (organization or user)"
  type        = string
  default     = "adyela"
}

variable "github_repo" {
  description = "GitHub repository name"
  type        = string
  default     = "adyela"
}

variable "vpc_connector_name" {
  description = "VPC connector name for private access (production only)"
  type        = string
  default     = null
}
