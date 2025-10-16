# ================================================================================
# Cloud Run Module Variables
# ================================================================================

variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
}

variable "environment" {
  description = "Environment (staging, production)"
  type        = string
}

variable "region" {
  description = "GCP region"
  type        = string
  default     = "us-central1"
}

variable "app_version" {
  description = "Application version"
  type        = string
  default     = "latest"
}

variable "service_account_email" {
  description = "Service account email for Cloud Run services"
  type        = string
}

variable "vpc_connector_name" {
  description = "VPC Access Connector name"
  type        = string
}

variable "api_image" {
  description = "Docker image for API service"
  type        = string
}

variable "web_image" {
  description = "Docker image for Web service"
  type        = string
}

variable "hipaa_secrets" {
  description = "Map of HIPAA secrets for API service"
  type        = map(string)
  default     = {}
}

variable "labels" {
  description = "Labels to apply to resources"
  type        = map(string)
  default     = {}
}

variable "api_url" {
  description = "URL of the API backend for the web frontend"
  type        = string
}

variable "min_instances" {
  description = "Minimum number of instances (0 = scale-to-zero, 1+ = always-on)"
  type        = number
  default     = 0
}

variable "max_instances" {
  description = "Maximum number of instances"
  type        = number
  default     = 10
}
