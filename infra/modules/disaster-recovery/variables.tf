# Disaster Recovery Module - Variables
# CONFIGURATION ONLY - Review and adjust before production activation

# ============================================================================
# PROJECT CONFIGURATION
# ============================================================================

variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "environment" {
  description = "Environment name (staging, production)"
  type        = string
  validation {
    condition     = contains(["staging", "production"], var.environment)
    error_message = "DR should only be enabled for production environments."
  }
}

variable "labels" {
  description = "Common labels for all DR resources"
  type        = map(string)
  default     = {}
}

# ============================================================================
# REGIONAL CONFIGURATION
# ============================================================================

variable "primary_region" {
  description = "Primary GCP region for production workloads"
  type        = string
  default     = "us-central1"
}

variable "secondary_region" {
  description = "Secondary GCP region for disaster recovery failover"
  type        = string
  default     = "us-east1"

  validation {
    condition     = var.secondary_region != var.primary_region
    error_message = "Secondary region must be different from primary region."
  }
}

# ============================================================================
# RTO/RPO TARGETS
# ============================================================================

variable "rto_minutes" {
  description = "Recovery Time Objective in minutes (time to restore service)"
  type        = number
  default     = 15

  validation {
    condition     = var.rto_minutes > 0 && var.rto_minutes <= 60
    error_message = "RTO must be between 1 and 60 minutes."
  }
}

variable "rpo_minutes" {
  description = "Recovery Point Objective in minutes (acceptable data loss)"
  type        = number
  default     = 60

  validation {
    condition     = var.rpo_minutes > 0 && var.rpo_minutes <= 240
    error_message = "RPO must be between 1 and 240 minutes."
  }
}

# ============================================================================
# DISASTER RECOVERY COMPONENTS (Feature Flags)
# ============================================================================

variable "enable_cloud_run_dr" {
  description = "Enable multi-region Cloud Run deployment for DR"
  type        = bool
  default     = false # Set to true when activating in production
}

variable "enable_firestore_dr" {
  description = "Enable Firestore multi-region replication for DR"
  type        = bool
  default     = false # Set to true when activating in production
}

variable "enable_cloud_sql_dr" {
  description = "Enable Cloud SQL cross-region read replicas for DR"
  type        = bool
  default     = false # Set to true when activating in production
}

variable "enable_storage_dr" {
  description = "Enable cross-region storage replication for DR"
  type        = bool
  default     = false # Set to true when activating in production
}

variable "enable_dr_monitoring" {
  description = "Enable monitoring and alerting for DR infrastructure"
  type        = bool
  default     = true # Always enable monitoring when DR is active
}

# ============================================================================
# CLOUD RUN DISASTER RECOVERY CONFIGURATION
# ============================================================================

variable "cloud_run_services" {
  description = "Cloud Run services to deploy in secondary region for DR"
  type = list(object({
    name          = string
    image         = string
    cpu_limit     = optional(string, "1")
    memory_limit  = optional(string, "512Mi")
    min_instances = optional(number, 0)
    max_instances = optional(number, 10)
    env_vars      = optional(map(string), {})
    secrets       = optional(map(string), {})
  }))
  default = []

  # Example:
  # [
  #   {
  #     name  = "adyela-web"
  #     image = "gcr.io/PROJECT_ID/adyela-web:latest"
  #     min_instances = 0  # Standby mode
  #     max_instances = 10
  #   },
  #   {
  #     name  = "adyela-api"
  #     image = "gcr.io/PROJECT_ID/adyela-api:latest"
  #     min_instances = 0  # Standby mode
  #     max_instances = 10
  #   }
  # ]
}

variable "min_secondary_instances" {
  description = "Minimum instances for secondary region services (0 = standby, >0 = warm standby)"
  type        = number
  default     = 0 # Cold standby to minimize costs

  validation {
    condition     = var.min_secondary_instances >= 0 && var.min_secondary_instances <= 5
    error_message = "Min instances should be 0 (cold standby) or 1-5 (warm standby)."
  }
}

variable "health_check_path" {
  description = "Health check path for Cloud Run services"
  type        = string
  default     = "/health"
}

variable "failover_threshold" {
  description = "Number of consecutive health check failures before failover"
  type        = number
  default     = 3
}

# ============================================================================
# FIRESTORE DISASTER RECOVERY CONFIGURATION
# ============================================================================

variable "firestore_multi_region_location" {
  description = "Multi-region location for Firestore (nam5, eur3, etc.)"
  type        = string
  default     = "nam5" # North America (covers us-central1 and us-east1)

  validation {
    condition     = contains(["nam5", "eur3"], var.firestore_multi_region_location)
    error_message = "Must be a valid multi-region location (nam5 for North America, eur3 for Europe)."
  }
}

variable "firestore_consistency_model" {
  description = "Consistency model for Firestore replication (STRONG or EVENTUAL)"
  type        = string
  default     = "STRONG"

  validation {
    condition     = contains(["STRONG", "EVENTUAL"], var.firestore_consistency_model)
    error_message = "Must be STRONG (recommended for DR) or EVENTUAL (lower cost)."
  }
}

variable "dr_backup_retention_days" {
  description = "Backup retention period for DR (days)"
  type        = number
  default     = 90 # 3 months for production

  validation {
    condition     = var.dr_backup_retention_days >= 7 && var.dr_backup_retention_days <= 365
    error_message = "Backup retention must be between 7 and 365 days."
  }
}

# ============================================================================
# CLOUD SQL DISASTER RECOVERY CONFIGURATION
# ============================================================================

variable "cloud_sql_primary_instance" {
  description = "Primary Cloud SQL instance name to create replica for"
  type        = string
  default     = ""
}

variable "cloud_sql_replica_tier" {
  description = "Machine tier for Cloud SQL read replica"
  type        = string
  default     = "db-custom-2-7680" # 2 vCPU, 7.5GB RAM
}

variable "cloud_sql_replica_disk_size" {
  description = "Disk size for Cloud SQL read replica (GB)"
  type        = number
  default     = 100
}

# ============================================================================
# STORAGE DISASTER RECOVERY CONFIGURATION
# ============================================================================

variable "storage_buckets_for_dr" {
  description = "Storage buckets to configure for cross-region replication"
  type = list(object({
    name          = string
    storage_class = optional(string, "STANDARD")
    versioning    = optional(bool, true)
  }))
  default = []

  # Example:
  # [
  #   {
  #     name = "adyela-production-uploads"
  #     storage_class = "STANDARD"
  #     versioning = true
  #   },
  #   {
  #     name = "adyela-production-backups"
  #     storage_class = "NEARLINE"
  #     versioning = true
  #   }
  # ]
}

variable "storage_replication_type" {
  description = "Storage replication type (dual-region or multi-region)"
  type        = string
  default     = "dual-region"

  validation {
    condition     = contains(["dual-region", "multi-region"], var.storage_replication_type)
    error_message = "Must be 'dual-region' (lower latency) or 'multi-region' (higher availability)."
  }
}

variable "storage_dr_location" {
  description = "Dual-region or multi-region location for storage"
  type        = string
  default     = "US" # Multi-region: US (covers all US regions)
  # Alternative: "NAM4" for dual-region Iowa+South Carolina
}

variable "enable_storage_turbo_replication" {
  description = "Enable turbo replication for RPO <15min (additional cost)"
  type        = bool
  default     = false # Enable for critical data with strict RPO
}

variable "storage_dr_lifecycle_rules" {
  description = "Lifecycle rules for DR storage buckets"
  type = list(object({
    action = object({
      type          = string
      storage_class = optional(string)
    })
    condition = object({
      age                = optional(number)
      num_newer_versions = optional(number)
      with_state         = optional(string)
    })
  }))
  default = [
    {
      action = {
        type          = "SetStorageClass"
        storage_class = "NEARLINE"
      }
      condition = {
        age = 30 # Move to NEARLINE after 30 days
      }
    },
    {
      action = {
        type          = "SetStorageClass"
        storage_class = "COLDLINE"
      }
      condition = {
        age = 90 # Move to COLDLINE after 90 days
      }
    },
    {
      action = {
        type = "Delete"
      }
      condition = {
        age                = 365 # Delete after 1 year
        num_newer_versions = 3   # Keep latest 3 versions
      }
    }
  ]
}

# ============================================================================
# MONITORING AND ALERTING CONFIGURATION
# ============================================================================

variable "dr_notification_channels" {
  description = "Notification channels for DR alerts (email, PagerDuty, Slack)"
  type        = list(string)
  default     = []

  # Example:
  # [
  #   "projects/PROJECT_ID/notificationChannels/CHANNEL_ID_EMAIL",
  #   "projects/PROJECT_ID/notificationChannels/CHANNEL_ID_PAGERDUTY"
  # ]
}

# ============================================================================
# COST CONTROL SETTINGS
# ============================================================================

variable "enable_cost_alerts" {
  description = "Enable cost alerts for DR infrastructure"
  type        = bool
  default     = true
}

variable "monthly_dr_budget_usd" {
  description = "Monthly budget for DR infrastructure (USD)"
  type        = number
  default     = 500 # $500/month alert threshold

  validation {
    condition     = var.monthly_dr_budget_usd >= 100 && var.monthly_dr_budget_usd <= 2000
    error_message = "DR budget should be between $100 and $2000/month."
  }
}

variable "budget_alert_thresholds" {
  description = "Budget alert thresholds (% of monthly budget)"
  type        = list(number)
  default     = [0.5, 0.75, 0.9, 1.0] # Alert at 50%, 75%, 90%, 100%
}
