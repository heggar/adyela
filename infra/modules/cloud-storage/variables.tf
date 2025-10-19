# Cloud Storage Module Variables

variable "project_id" {
  description = "The GCP project ID"
  type        = string
}

variable "bucket_name" {
  description = "Name of the Cloud Storage bucket (must be globally unique)"
  type        = string
}

variable "location" {
  description = "Location of the bucket (us-central1, us, EU, ASIA, etc.)"
  type        = string
  default     = "us-central1"
}

variable "environment" {
  description = "Environment (staging, production, development)"
  type        = string
}

variable "storage_class" {
  description = "Storage class (STANDARD, NEARLINE, COLDLINE, ARCHIVE)"
  type        = string
  default     = "STANDARD"

  validation {
    condition     = contains(["STANDARD", "NEARLINE", "COLDLINE", "ARCHIVE"], var.storage_class)
    error_message = "Storage class must be one of: STANDARD, NEARLINE, COLDLINE, ARCHIVE"
  }
}

variable "uniform_bucket_level_access" {
  description = "Enable uniform bucket-level access (recommended for security)"
  type        = bool
  default     = true
}

variable "public_access_prevention" {
  description = "Public access prevention (enforced or inherited)"
  type        = string
  default     = "enforced"

  validation {
    condition     = contains(["enforced", "inherited"], var.public_access_prevention)
    error_message = "Public access prevention must be 'enforced' or 'inherited'"
  }
}

variable "versioning_enabled" {
  description = "Enable object versioning"
  type        = bool
  default     = false
}

variable "lifecycle_rules" {
  description = "Lifecycle management rules for cost optimization"
  type = list(object({
    action = object({
      type          = string
      storage_class = optional(string)
    })
    condition = object({
      age                        = optional(number)
      created_before             = optional(string)
      with_state                 = optional(string)
      matches_storage_class      = optional(list(string))
      matches_prefix             = optional(list(string))
      matches_suffix             = optional(list(string))
      num_newer_versions         = optional(number)
      days_since_custom_time     = optional(number)
      days_since_noncurrent_time = optional(number)
    })
  }))
  default = []
}

variable "cors_config" {
  description = "CORS configuration for web access"
  type = object({
    origin          = list(string)
    method          = list(string)
    response_header = optional(list(string))
    max_age_seconds = optional(number)
  })
  default = null
}

variable "encryption_key" {
  description = "Cloud KMS key name for encryption (optional)"
  type        = string
  default     = null
}

variable "website_config" {
  description = "Website configuration for static hosting"
  type = object({
    main_page_suffix = optional(string)
    not_found_page   = optional(string)
  })
  default = null
}

variable "logging_config" {
  description = "Access logging configuration"
  type = object({
    log_bucket        = string
    log_object_prefix = optional(string)
  })
  default = null
}

variable "retention_policy" {
  description = "Retention policy for compliance (objects cannot be deleted before retention period)"
  type = object({
    retention_period = number
    is_locked        = optional(bool)
  })
  default = null
}

variable "enable_autoclass" {
  description = "Enable autoclass for automatic storage class transitions"
  type        = bool
  default     = false
}

variable "autoclass_terminal_storage_class" {
  description = "Terminal storage class for autoclass (NEARLINE, COLDLINE, ARCHIVE)"
  type        = string
  default     = "NEARLINE"

  validation {
    condition     = contains(["NEARLINE", "COLDLINE", "ARCHIVE"], var.autoclass_terminal_storage_class)
    error_message = "Autoclass terminal storage class must be NEARLINE, COLDLINE, or ARCHIVE"
  }
}

variable "labels" {
  description = "Labels from common module"
  type        = map(string)
  default     = {}
}

variable "force_destroy" {
  description = "Allow Terraform to delete non-empty buckets (use with caution)"
  type        = bool
  default     = false
}

# IAM Members
variable "reader_members" {
  description = "List of members with read access (storage.objectViewer)"
  type        = list(string)
  default     = []
}

variable "writer_members" {
  description = "List of members with write access (storage.objectCreator)"
  type        = list(string)
  default     = []
}

variable "admin_members" {
  description = "List of members with admin access (storage.objectAdmin)"
  type        = list(string)
  default     = []
}

variable "make_public" {
  description = "Make bucket publicly accessible (for static websites)"
  type        = bool
  default     = false
}

# Notifications
variable "notification_config" {
  description = "Pub/Sub notification configuration"
  type = object({
    topic              = string
    payload_format     = string
    event_types        = optional(list(string))
    custom_attributes  = optional(map(string))
    object_name_prefix = optional(string)
  })
  default = null
}
