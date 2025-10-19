# Firestore Module Variables

variable "project_id" {
  description = "The GCP project ID"
  type        = string
}

variable "database_name" {
  description = "Name of the Firestore database ((default) for default database)"
  type        = string
  default     = "(default)"
}

variable "location" {
  description = "Location of the database (us-central1, nam5, eur3, etc.)"
  type        = string
  default     = "nam5" # North America multi-region
}

variable "database_type" {
  description = "Database type (FIRESTORE_NATIVE or DATASTORE_MODE)"
  type        = string
  default     = "FIRESTORE_NATIVE"

  validation {
    condition     = contains(["FIRESTORE_NATIVE", "DATASTORE_MODE"], var.database_type)
    error_message = "Database type must be FIRESTORE_NATIVE or DATASTORE_MODE"
  }
}

variable "concurrency_mode" {
  description = "Concurrency mode (OPTIMISTIC, PESSIMISTIC, or OPTIMISTIC_WITH_ENTITY_GROUPS)"
  type        = string
  default     = "OPTIMISTIC"

  validation {
    condition     = contains(["OPTIMISTIC", "PESSIMISTIC", "OPTIMISTIC_WITH_ENTITY_GROUPS"], var.concurrency_mode)
    error_message = "Concurrency mode must be OPTIMISTIC, PESSIMISTIC, or OPTIMISTIC_WITH_ENTITY_GROUPS"
  }
}

variable "app_engine_integration_mode" {
  description = "App Engine integration mode (ENABLED or DISABLED)"
  type        = string
  default     = "DISABLED"

  validation {
    condition     = contains(["ENABLED", "DISABLED"], var.app_engine_integration_mode)
    error_message = "App Engine integration mode must be ENABLED or DISABLED"
  }
}

variable "enable_pitr" {
  description = "Enable Point-in-Time Recovery (7-day retention)"
  type        = bool
  default     = true
}

variable "delete_protection" {
  description = "Enable delete protection (prevents accidental deletion)"
  type        = bool
  default     = true
}

variable "force_destroy" {
  description = "Allow Terraform to delete the database (use with caution)"
  type        = bool
  default     = false
}

# Indexes
variable "indexes" {
  description = "Firestore indexes for query optimization"
  type = list(object({
    name        = string
    collection  = string
    query_scope = optional(string)
    fields = list(object({
      field_path   = string
      order        = optional(string) # ASC or DESC
      array_config = optional(string) # CONTAINS
    }))
  }))
  default = []
}

# Security Rules
variable "security_rules_file" {
  description = "Path to firestore.rules file (relative to Terraform root)"
  type        = string
  default     = null
}

# Backups
variable "enable_backups" {
  description = "Enable automated daily backups"
  type        = bool
  default     = true
}

variable "backup_retention_days" {
  description = "Number of days to retain backups (default: 7 days)"
  type        = number
  default     = 7

  validation {
    condition     = var.backup_retention_days >= 1 && var.backup_retention_days <= 365
    error_message = "Backup retention must be between 1 and 365 days"
  }
}

# Export Bucket
variable "create_export_bucket" {
  description = "Create a Cloud Storage bucket for Firestore exports"
  type        = bool
  default     = true
}

# IAM Members
variable "firestore_users" {
  description = "List of members with Firestore user access (read/write)"
  type        = list(string)
  default     = []
}

variable "firestore_viewers" {
  description = "List of members with Firestore viewer access (read-only)"
  type        = list(string)
  default     = []
}

variable "firestore_owners" {
  description = "List of members with Firestore owner access (admin)"
  type        = list(string)
  default     = []
}

# Labels
variable "labels" {
  description = "Labels from common module"
  type        = map(string)
  default     = {}
}
