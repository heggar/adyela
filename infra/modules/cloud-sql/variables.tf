# Cloud SQL PostgreSQL Module Variables

variable "project_id" {
  description = "The GCP project ID"
  type        = string
}

variable "instance_name" {
  description = "Name of the Cloud SQL instance"
  type        = string
}

variable "region" {
  description = "Region for the Cloud SQL instance"
  type        = string
  default     = "us-central1"
}

variable "environment" {
  description = "Environment (staging, production, development)"
  type        = string
}

variable "database_version" {
  description = "PostgreSQL version (POSTGRES_14, POSTGRES_15, POSTGRES_16)"
  type        = string
  default     = "POSTGRES_15"

  validation {
    condition     = can(regex("^POSTGRES_", var.database_version))
    error_message = "Database version must be a PostgreSQL version (POSTGRES_14, POSTGRES_15, POSTGRES_16)"
  }
}

variable "tier" {
  description = "Machine type tier (db-f1-micro, db-g1-small, db-custom-CPU-RAM)"
  type        = string
  default     = "db-custom-2-7680" # 2 vCPU, 7.5 GB RAM
}

variable "high_availability" {
  description = "Enable high availability (REGIONAL) with automatic failover"
  type        = bool
  default     = false
}

variable "disk_type" {
  description = "Disk type (PD_SSD or PD_HDD)"
  type        = string
  default     = "PD_SSD"

  validation {
    condition     = contains(["PD_SSD", "PD_HDD"], var.disk_type)
    error_message = "Disk type must be PD_SSD or PD_HDD"
  }
}

variable "disk_size" {
  description = "Disk size in GB"
  type        = number
  default     = 10

  validation {
    condition     = var.disk_size >= 10 && var.disk_size <= 65536
    error_message = "Disk size must be between 10 and 65536 GB"
  }
}

variable "disk_autoresize" {
  description = "Enable automatic disk size increase"
  type        = bool
  default     = true
}

variable "deletion_protection" {
  description = "Prevent accidental deletion of the instance"
  type        = bool
  default     = true
}

# Backup Configuration
variable "enable_backups" {
  description = "Enable automated backups"
  type        = bool
  default     = true
}

variable "backup_start_time" {
  description = "Backup start time (HH:MM format, UTC)"
  type        = string
  default     = "03:00"
}

variable "enable_pitr" {
  description = "Enable Point-in-Time Recovery"
  type        = bool
  default     = true
}

variable "transaction_log_retention_days" {
  description = "Transaction log retention for PITR (1-7 days)"
  type        = number
  default     = 7

  validation {
    condition     = var.transaction_log_retention_days >= 1 && var.transaction_log_retention_days <= 7
    error_message = "Transaction log retention must be between 1 and 7 days"
  }
}

variable "backup_retention_count" {
  description = "Number of backups to retain"
  type        = number
  default     = 30
}

# Network Configuration
variable "enable_public_ip" {
  description = "Enable public IP address"
  type        = bool
  default     = false
}

variable "private_network" {
  description = "VPC network for private IP (required if enable_public_ip = false)"
  type        = string
  default     = null
}

variable "require_ssl" {
  description = "Require SSL for connections"
  type        = bool
  default     = true
}

variable "authorized_networks" {
  description = "List of authorized networks for public IP access"
  type = list(object({
    name = string
    cidr = string
  }))
  default = []
}

# Maintenance Window
variable "maintenance_window" {
  description = "Maintenance window configuration"
  type = object({
    day          = number # 1 = Monday, 7 = Sunday
    hour         = number # 0-23
    update_track = string # stable or canary
  })
  default = {
    day          = 7 # Sunday
    hour         = 3 # 3 AM UTC
    update_track = "stable"
  }
}

# Database Flags (PostgreSQL Configuration)
variable "database_flags" {
  description = "PostgreSQL database flags"
  type = list(object({
    name  = string
    value = string
  }))
  default = []
}

# Query Insights
variable "enable_query_insights" {
  description = "Enable Query Insights for performance monitoring"
  type        = bool
  default     = true
}

variable "query_insights_query_string_length" {
  description = "Maximum query string length for Query Insights"
  type        = number
  default     = 1024
}

variable "query_insights_record_application_tags" {
  description = "Record application tags in Query Insights"
  type        = bool
  default     = true
}

variable "query_insights_record_client_address" {
  description = "Record client address in Query Insights"
  type        = bool
  default     = true
}

# Databases
variable "databases" {
  description = "List of database names to create"
  type        = list(string)
  default     = []
}

variable "database_charset" {
  description = "Database character set"
  type        = string
  default     = "UTF8"
}

variable "database_collation" {
  description = "Database collation"
  type        = string
  default     = "en_US.UTF8"
}

# Users
variable "create_admin_user" {
  description = "Create an admin user with random password"
  type        = bool
  default     = true
}

variable "admin_user_name" {
  description = "Admin user name"
  type        = string
  default     = "admin"
}

variable "store_password_in_secret_manager" {
  description = "Store admin password in Secret Manager"
  type        = bool
  default     = true
}

variable "additional_users" {
  description = "Additional database users to create"
  type = map(object({
    password = string
  }))
  default   = {}
  sensitive = true
}

# Read Replicas
variable "read_replicas" {
  description = "Read replica configurations"
  type = map(object({
    region          = string
    tier            = optional(string)
    failover_target = optional(bool)
  }))
  default = {}
}

# IAM Members
variable "sql_client_members" {
  description = "Members with Cloud SQL Client role"
  type        = list(string)
  default     = []
}

variable "sql_admin_members" {
  description = "Members with Cloud SQL Admin role"
  type        = list(string)
  default     = []
}

# Labels
variable "labels" {
  description = "Labels from common module"
  type        = map(string)
  default     = {}
}
