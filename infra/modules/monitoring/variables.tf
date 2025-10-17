variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
}

variable "environment" {
  description = "Environment name (staging, production)"
  type        = string
}

variable "domain" {
  description = "Primary domain for monitoring"
  type        = string
}

variable "alert_email" {
  description = "Email address for alerts"
  type        = string
}

variable "enable_sms_alerts" {
  description = "Enable SMS alerts for critical issues"
  type        = bool
  default     = false
}

variable "alert_phone_number" {
  description = "Phone number for SMS alerts (E.164 format: +1234567890)"
  type        = string
  default     = ""
}

variable "labels" {
  description = "Labels to apply to resources"
  type        = map(string)
  default     = {}
}
