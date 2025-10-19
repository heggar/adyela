# Cross-Region Storage Disaster Recovery - Variables
# CONFIGURATION ONLY - FOR PRODUCTION ACTIVATION ONLY

variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

# ============================================================================
# BUCKET CONFIGURATION
# ============================================================================

variable "buckets" {
  description = "Storage buckets to configure for cross-region DR"
  type = list(object({
    name          = string
    storage_class = optional(string, "STANDARD")
    versioning    = optional(bool, true)
    quota_gb      = optional(number, 0) # Set to 0 for no quota
    lifecycle_rules = optional(list(object({
      action = object({
        type          = string
        storage_class = optional(string)
      })
      condition = object({
        age                        = optional(number)
        created_before             = optional(string)
        with_state                 = optional(string)
        matches_storage_class      = optional(list(string))
        num_newer_versions         = optional(number)
        days_since_noncurrent_time = optional(number)
      })
    })), [])
    enable_cors    = optional(bool, false)
    cors_origins   = optional(list(string), ["*"])
    cors_methods   = optional(list(string), ["GET", "HEAD"])
    viewer_members = optional(list(string), [])
    admin_members  = optional(list(string), [])
  }))

  validation {
    condition     = length(var.buckets) > 0
    error_message = "At least one bucket must be configured for DR."
  }

  # Example:
  # [
  #   {
  #     name          = "adyela-production-uploads"
  #     storage_class = "STANDARD"
  #     versioning    = true
  #     quota_gb      = 500
  #   },
  #   {
  #     name          = "adyela-production-backups"
  #     storage_class = "NEARLINE"
  #     versioning    = true
  #     quota_gb      = 1000
  #   }
  # ]
}

# ============================================================================
# REPLICATION CONFIGURATION
# ============================================================================

variable "replication_type" {
  description = "Storage replication type (dual-region or multi-region)"
  type        = string
  default     = "dual-region"

  validation {
    condition     = contains(["dual-region", "multi-region"], var.replication_type)
    error_message = "Must be 'dual-region' (lower latency) or 'multi-region' (higher availability)."
  }
}

variable "dr_location" {
  description = "Dual-region or multi-region location for storage"
  type        = string
  default     = "US" # Multi-region: US (all US regions)

  # Common options:
  # - Multi-region: US, EU, ASIA
  # - Dual-region: NAM4 (Iowa + South Carolina), EUR4 (Netherlands + Finland)

  validation {
    condition     = can(regex("^(US|EU|ASIA|NAM4|EUR4)$", var.dr_location))
    error_message = "Must be a valid multi-region (US, EU, ASIA) or dual-region (NAM4, EUR4) location."
  }
}

variable "enable_turbo_replication" {
  description = "Enable turbo replication for RPO <15min (additional cost, dual-region only)"
  type        = bool
  default     = false

  # Note: Turbo replication only works with dual-region buckets
  # Provides 99.95% availability SLA and <15min RPO
  # Cost: +$0.04/GB for replication
}

variable "turbo_replication_regions" {
  description = "Specific regions for turbo replication (required if enable_turbo_replication=true)"
  type        = list(string)
  default     = ["us-central1", "us-east1"]

  validation {
    condition     = length(var.turbo_replication_regions) == 2
    error_message = "Turbo replication requires exactly 2 regions."
  }
}

# ============================================================================
# LIFECYCLE CONFIGURATION
# ============================================================================

variable "version_retention_days" {
  description = "Number of days to retain old object versions"
  type        = number
  default     = 365 # 1 year

  validation {
    condition     = var.version_retention_days >= 30 && var.version_retention_days <= 3650
    error_message = "Version retention must be between 30 days and 10 years."
  }
}

# ============================================================================
# SECURITY CONFIGURATION
# ============================================================================

variable "kms_key_name" {
  description = "KMS key for bucket encryption (CMEK)"
  type        = string
  default     = null

  # Format: projects/PROJECT_ID/locations/LOCATION/keyRings/RING_NAME/cryptoKeys/KEY_NAME
  # Recommended for compliance (HIPAA, GDPR)
}

variable "access_logging_bucket" {
  description = "Bucket name for access logs (for audit trail)"
  type        = string
  default     = null
}

variable "allow_force_destroy" {
  description = "Allow force destroy of buckets (NEVER true in production)"
  type        = bool
  default     = false

  validation {
    condition     = var.allow_force_destroy == false
    error_message = "Force destroy must be disabled for production DR buckets."
  }
}

variable "prevent_bucket_destroy" {
  description = "Prevent accidental bucket destruction via Terraform"
  type        = bool
  default     = true
}

# ============================================================================
# MONITORING CONFIGURATION
# ============================================================================

variable "enable_monitoring" {
  description = "Enable monitoring alerts for storage buckets"
  type        = bool
  default     = true
}

variable "notification_channels" {
  description = "Notification channels for DR alerts"
  type        = list(string)
  default     = []
}

# ============================================================================
# LABELS
# ============================================================================

variable "labels" {
  description = "Labels for DR storage resources"
  type        = map(string)
  default     = {}
}
