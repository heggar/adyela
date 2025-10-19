# Cloud SQL Disaster Recovery - Variables
# CONFIGURATION ONLY - FOR PRODUCTION ACTIVATION ONLY

variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

# ============================================================================
# PRIMARY INSTANCE CONFIGURATION
# ============================================================================

variable "primary_instance_name" {
  description = "Name of the primary Cloud SQL instance to create replica for"
  type        = string
}

variable "primary_instance_id" {
  description = "Full resource ID of the primary Cloud SQL instance (projects/PROJECT/instances/INSTANCE)"
  type        = string
}

variable "primary_instance_region" {
  description = "Region of the primary Cloud SQL instance"
  type        = string
  default     = "us-central1"
}

variable "database_version" {
  description = "Database version (must match primary instance)"
  type        = string
  default     = "POSTGRES_15"

  validation {
    condition     = can(regex("^POSTGRES_", var.database_version))
    error_message = "Database version must be a PostgreSQL version (e.g., POSTGRES_15)."
  }
}

# ============================================================================
# DR REPLICA CONFIGURATION
# ============================================================================

variable "secondary_region" {
  description = "Secondary GCP region for DR replica"
  type        = string
  default     = "us-east1"

  validation {
    condition     = var.secondary_region != var.primary_instance_region
    error_message = "Secondary region must be different from primary region."
  }
}

variable "replica_tier" {
  description = "Machine tier for DR replica (should match or exceed primary)"
  type        = string
  default     = "db-custom-2-7680" # 2 vCPU, 7.5GB RAM

  validation {
    condition     = can(regex("^db-", var.replica_tier))
    error_message = "Replica tier must be a valid Cloud SQL tier (e.g., db-custom-2-7680)."
  }
}

variable "replica_high_availability" {
  description = "Enable regional high availability for DR replica (REGIONAL vs ZONAL)"
  type        = bool
  default     = false # ZONAL for cost optimization, REGIONAL for production DR
}

# ============================================================================
# DISK CONFIGURATION
# ============================================================================

variable "disk_type" {
  description = "Disk type for replica (SSD recommended for production)"
  type        = string
  default     = "PD_SSD"

  validation {
    condition     = contains(["PD_SSD", "PD_HDD"], var.disk_type)
    error_message = "Disk type must be PD_SSD or PD_HDD."
  }
}

variable "disk_size" {
  description = "Initial disk size in GB (should match or exceed primary)"
  type        = number
  default     = 100

  validation {
    condition     = var.disk_size >= 10 && var.disk_size <= 65536
    error_message = "Disk size must be between 10 and 65536 GB."
  }
}

variable "disk_autoresize_limit" {
  description = "Maximum disk size in GB for autoresize (cost protection)"
  type        = number
  default     = 500

  validation {
    condition     = var.disk_autoresize_limit >= var.disk_size
    error_message = "Autoresize limit must be >= initial disk size."
  }
}

# ============================================================================
# NETWORKING CONFIGURATION
# ============================================================================

variable "enable_public_ip" {
  description = "Enable public IP for replica (should match primary)"
  type        = bool
  default     = false
}

variable "private_network" {
  description = "Private VPC network for replica (should match primary)"
  type        = string
  default     = null
}

variable "require_ssl" {
  description = "Require SSL for connections (should match primary)"
  type        = bool
  default     = true
}

variable "authorized_networks" {
  description = "Authorized networks for public IP access (if enabled)"
  type = list(object({
    name = string
    cidr = string
  }))
  default = []
}

# ============================================================================
# BACKUP CONFIGURATION (OPTIONAL FOR REPLICAS)
# ============================================================================

variable "enable_replica_backups" {
  description = "Enable backups on replica (recommended for DR)"
  type        = bool
  default     = true
}

variable "enable_replica_pitr" {
  description = "Enable Point-in-Time Recovery on replica"
  type        = bool
  default     = false # Usually not needed for replicas, saves cost
}

variable "backup_start_time" {
  description = "Backup start time (HH:MM format, UTC)"
  type        = string
  default     = "03:00"

  validation {
    condition     = can(regex("^([01][0-9]|2[0-3]):[0-5][0-9]$", var.backup_start_time))
    error_message = "Backup start time must be in HH:MM format (00:00 to 23:59)."
  }
}

variable "backup_retention_count" {
  description = "Number of backups to retain"
  type        = number
  default     = 7

  validation {
    condition     = var.backup_retention_count >= 1 && var.backup_retention_count <= 365
    error_message = "Backup retention must be between 1 and 365."
  }
}

# ============================================================================
# MAINTENANCE CONFIGURATION
# ============================================================================

variable "maintenance_window_day" {
  description = "Day of week for maintenance (1=Monday, 7=Sunday)"
  type        = number
  default     = 7 # Sunday

  validation {
    condition     = var.maintenance_window_day >= 1 && var.maintenance_window_day <= 7
    error_message = "Maintenance window day must be between 1 (Monday) and 7 (Sunday)."
  }
}

variable "maintenance_window_hour" {
  description = "Hour of day for maintenance (0-23, UTC)"
  type        = number
  default     = 4 # 4 AM UTC

  validation {
    condition     = var.maintenance_window_hour >= 0 && var.maintenance_window_hour <= 23
    error_message = "Maintenance window hour must be between 0 and 23."
  }
}

# ============================================================================
# DATABASE FLAGS (SHOULD MATCH PRIMARY)
# ============================================================================

variable "database_flags" {
  description = "Database flags for PostgreSQL configuration (should match primary)"
  type = list(object({
    name  = string
    value = string
  }))
  default = []
}

# ============================================================================
# MONITORING CONFIGURATION
# ============================================================================

variable "enable_monitoring" {
  description = "Enable monitoring alerts for replica lag and health"
  type        = bool
  default     = true
}

variable "enable_query_insights" {
  description = "Enable Query Insights for performance monitoring"
  type        = bool
  default     = true
}

variable "replica_lag_threshold_seconds" {
  description = "Alert threshold for replica lag (seconds)"
  type        = number
  default     = 300 # 5 minutes

  validation {
    condition     = var.replica_lag_threshold_seconds >= 60 && var.replica_lag_threshold_seconds <= 3600
    error_message = "Replica lag threshold must be between 60 and 3600 seconds."
  }
}

variable "notification_channels" {
  description = "Notification channels for DR alerts"
  type        = list(string)
  default     = []
}

# ============================================================================
# PROTECTION SETTINGS
# ============================================================================

variable "deletion_protection" {
  description = "Enable deletion protection (ALWAYS true for production)"
  type        = bool
  default     = true
}

# ============================================================================
# DOCUMENTATION
# ============================================================================

variable "create_failover_docs" {
  description = "Create failover procedure documentation"
  type        = bool
  default     = true
}

# ============================================================================
# LABELS
# ============================================================================

variable "labels" {
  description = "Labels for DR resources"
  type        = map(string)
  default     = {}
}
