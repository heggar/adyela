# Firestore Multi-Region Replication - Variables

variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "database_name" {
  description = "Firestore database name (use different name during migration)"
  type        = string
  default     = "(default)"
}

variable "location_id" {
  description = "Multi-region location ID (nam5, eur3, etc.)"
  type        = string
  default     = "nam5"

  validation {
    condition     = contains(["nam5", "eur3"], var.location_id)
    error_message = "Must be a valid multi-region location."
  }
}

variable "backup_retention_days" {
  description = "Daily backup retention period (days)"
  type        = number
  default     = 90
}

variable "enable_weekly_backups" {
  description = "Enable weekly backups with extended retention"
  type        = bool
  default     = true
}

variable "weekly_backup_retention_days" {
  description = "Weekly backup retention period (days)"
  type        = number
  default     = 180
}

variable "export_retention_days" {
  description = "Export file retention period (days)"
  type        = number
  default     = 365
}

variable "enable_monitoring" {
  description = "Enable monitoring and alerting"
  type        = bool
  default     = true
}

variable "notification_channels" {
  description = "Notification channels for alerts"
  type        = list(string)
  default     = []
}

variable "create_migration_docs" {
  description = "Create migration instruction documentation"
  type        = bool
  default     = true
}

variable "labels" {
  description = "Resource labels"
  type        = map(string)
  default     = {}
}
