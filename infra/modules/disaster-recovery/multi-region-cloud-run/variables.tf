# Multi-Region Cloud Run Deployment - Variables
# CONFIGURATION ONLY - FOR PRODUCTION ACTIVATION ONLY
#
# These variables configure Cloud Run services in a secondary region for disaster
# recovery failover. Services run in cold standby mode by default to minimize costs.

variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "environment" {
  description = "Environment name (staging, production)"
  type        = string
}

# ============================================================================
# REGIONAL CONFIGURATION
# ============================================================================

variable "secondary_region" {
  description = "Secondary GCP region for disaster recovery (e.g., us-east1)"
  type        = string
  default     = "us-east1"

  validation {
    condition     = can(regex("^[a-z]+-[a-z]+[0-9]$", var.secondary_region))
    error_message = "Secondary region must be a valid GCP region (e.g., us-east1)."
  }
}

# ============================================================================
# CLOUD RUN SERVICES CONFIGURATION
# ============================================================================

variable "services" {
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

  validation {
    condition     = length(var.services) > 0
    error_message = "At least one service must be configured for DR."
  }
}

variable "min_secondary_instances" {
  description = "Minimum instances for secondary region services (0 = cold standby, >0 = warm standby)"
  type        = number
  default     = 0 # Cold standby to minimize costs

  validation {
    condition     = var.min_secondary_instances >= 0 && var.min_secondary_instances <= 5
    error_message = "Min instances should be 0 (cold standby) or 1-5 (warm standby)."
  }
}

# ============================================================================
# NETWORKING CONFIGURATION
# ============================================================================

variable "vpc_connector_name" {
  description = "VPC connector name for private networking (optional)"
  type        = string
  default     = null
}

variable "allow_public_access" {
  description = "Allow public access to secondary services (allUsers invoker)"
  type        = bool
  default     = false
}

# ============================================================================
# HEALTH CHECK CONFIGURATION
# ============================================================================

variable "health_check_path" {
  description = "Health check endpoint path for Cloud Run services"
  type        = string
  default     = "/health"

  validation {
    condition     = can(regex("^/.*", var.health_check_path))
    error_message = "Health check path must start with /."
  }
}

variable "failover_threshold" {
  description = "Number of consecutive health check failures before triggering failover"
  type        = number
  default     = 3

  validation {
    condition     = var.failover_threshold >= 2 && var.failover_threshold <= 10
    error_message = "Failover threshold must be between 2 and 10."
  }
}

# ============================================================================
# BACKEND SERVICE CONFIGURATION
# ============================================================================

variable "create_backend_service" {
  description = "Create backend service for load balancer integration"
  type        = bool
  default     = true
}

variable "security_policy_id" {
  description = "Cloud Armor security policy ID for backend service"
  type        = string
  default     = null
}

variable "enable_cdn" {
  description = "Enable Cloud CDN for backend service"
  type        = bool
  default     = false
}

# ============================================================================
# IAM CONFIGURATION
# ============================================================================

variable "service_account_email" {
  description = "Service account email for Cloud Run services"
  type        = string
}

# ============================================================================
# MONITORING CONFIGURATION
# ============================================================================

variable "enable_monitoring" {
  description = "Enable monitoring alerts for secondary services"
  type        = bool
  default     = true
}

variable "notification_channels" {
  description = "Notification channels for DR alerts"
  type        = list(string)
  default     = []
}

# ============================================================================
# LABELS AND METADATA
# ============================================================================

variable "labels" {
  description = "Common labels for all DR resources"
  type        = map(string)
  default     = {}
}
