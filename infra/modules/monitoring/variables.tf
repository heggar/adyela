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

variable "region" {
  description = "GCP region for resources"
  type        = string
  default     = "us-central1"
}

# ================================================================================
# Log Sinks Configuration
# ================================================================================

variable "enable_log_sinks" {
  description = "Enable log sinks to BigQuery for centralized analysis"
  type        = bool
  default     = true
}

variable "log_retention_days" {
  description = "Number of days to retain logs in BigQuery"
  type        = number
  default     = 90
}

# ================================================================================
# Error Reporting Configuration
# ================================================================================

variable "enable_error_reporting_alerts" {
  description = "Enable alerts for Error Reporting"
  type        = bool
  default     = true
}

# ================================================================================
# Cloud Trace Configuration
# ================================================================================

variable "enable_trace_alerts" {
  description = "Enable alerts for Cloud Trace latency"
  type        = bool
  default     = true
}

variable "trace_sampling_rate" {
  description = "Sampling rate for Cloud Trace (0.0 to 1.0)"
  type        = number
  default     = 1.0 # 100% sampling for staging, reduce for production

  validation {
    condition     = var.trace_sampling_rate >= 0.0 && var.trace_sampling_rate <= 1.0
    error_message = "Trace sampling rate must be between 0.0 and 1.0"
  }
}

# ================================================================================
# SLO Configuration
# ================================================================================

variable "availability_slo_target" {
  description = "Target availability SLO (e.g., 0.999 for 99.9%)"
  type        = number
  default     = 0.999

  validation {
    condition     = var.availability_slo_target >= 0.0 && var.availability_slo_target <= 1.0
    error_message = "SLO target must be between 0.0 and 1.0"
  }
}

variable "latency_slo_target_ms" {
  description = "Target latency SLO in milliseconds (P95)"
  type        = number
  default     = 1000 # 1 second
}

variable "error_rate_slo_target" {
  description = "Maximum acceptable error rate (e.g., 0.01 for 1%)"
  type        = number
  default     = 0.01

  validation {
    condition     = var.error_rate_slo_target >= 0.0 && var.error_rate_slo_target <= 1.0
    error_message = "Error rate SLO must be between 0.0 and 1.0"
  }
}

variable "slo_rolling_period_days" {
  description = "Rolling period for SLO calculations in days"
  type        = number
  default     = 30

  validation {
    condition     = contains([1, 7, 28, 30, 90], var.slo_rolling_period_days)
    error_message = "SLO rolling period must be 1, 7, 28, 30, or 90 days"
  }
}

# ================================================================================
# Dashboard Configuration
# ================================================================================

variable "enable_microservices_dashboards" {
  description = "Create individual dashboards for each microservice"
  type        = bool
  default     = true
}

variable "microservices" {
  description = "List of microservices to monitor"
  type = list(object({
    name         = string
    display_name = string
    service_type = string # "api", "worker", "frontend"
  }))
  default = []
}

# ================================================================================
# Notification Configuration
# ================================================================================

variable "enable_slack_notifications" {
  description = "Enable Slack notifications for alerts"
  type        = bool
  default     = false
}

variable "slack_webhook_url" {
  description = "Slack webhook URL for notifications"
  type        = string
  default     = ""
  sensitive   = true
}

variable "enable_pagerduty_notifications" {
  description = "Enable PagerDuty notifications for critical alerts"
  type        = bool
  default     = false
}

variable "pagerduty_integration_key" {
  description = "PagerDuty integration key"
  type        = string
  default     = ""
  sensitive   = true
}
