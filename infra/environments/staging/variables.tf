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

variable "billing_account" {
  description = "GCP billing account ID for budget alerts"
  type        = string
}

variable "budget_alert_emails" {
  description = "List of email addresses to receive budget alerts"
  type        = list(string)
  default     = ["hever_gonzalezg@adyela.care"]
}

variable "environment" {
  description = "Environment name (e.g., staging, production)"
  type        = string
  default     = "staging"
}

variable "artifact_registry_repository" {
  description = "Name of the Artifact Registry repository"
  type        = string
  default     = "adyela"
}

variable "allowed_ips" {
  description = "List of allowed IP addresses for Cloud Armor"
  type        = list(string)
  default     = []
}

variable "contact_email" {
  description = "Contact email for resource labels"
  type        = string
  default     = "hever_gonzalezg@adyela.care"
}
