variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "billing_account" {
  description = "GCP billing account ID"
  type        = string
}

variable "environment" {
  description = "Environment name (staging, production)"
  type        = string
}

variable "budget_amount" {
  description = "Monthly budget amount in USD"
  type        = number
  default     = 150 # Default to staging budget
}

variable "alert_email_addresses" {
  description = "Email addresses to receive budget alerts"
  type        = list(string)
  default     = []
}

variable "notification_channel_ids" {
  description = "Existing notification channel IDs for budget alerts"
  type        = list(string)
  default     = []
}

variable "budget_alert_webhook_url" {
  description = "Webhook URL for budget alerts (optional)"
  type        = string
  default     = ""
}

variable "enable_cost_spike_alerts" {
  description = "Enable alerts for unusual cost spikes"
  type        = bool
  default     = true
}
