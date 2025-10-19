# Secret Manager Module Variables

variable "project_id" {
  description = "The GCP project ID"
  type        = string
}

# Secrets Configuration
variable "secrets" {
  description = "List of secrets to create with their configurations"
  type = list(object({
    secret_id = string

    # Secret data (plaintext - will be encrypted by Secret Manager)
    secret_data        = optional(string)
    manage_secret_data = optional(bool) # If false, Terraform won't update secret_data
    enabled            = optional(bool)
    deletion_policy    = optional(string)

    # Auto-generate random secret
    generate_random         = optional(bool)
    random_length           = optional(number)
    random_special          = optional(bool)
    random_upper            = optional(bool)
    random_lower            = optional(bool)
    random_numeric          = optional(bool)
    random_override_special = optional(string)

    # Replication
    replication_policy = optional(string) # "automatic" or "user_managed"
    kms_key_name       = optional(string) # For automatic replication with CMEK
    replicas = optional(list(object({
      location     = string
      kms_key_name = optional(string)
    })))

    # Rotation
    rotation_period    = optional(string) # e.g., "2592000s" (30 days)
    next_rotation_time = optional(string)

    # Notifications
    topics = optional(list(object({
      name = string
    })))

    # Expiration
    expire_time = optional(string) # RFC 3339 timestamp
    ttl         = optional(string) # Duration, e.g., "3600s"

    # Version aliases
    version_aliases = optional(map(string))

    # Metadata
    labels      = optional(map(string))
    annotations = optional(map(string))

    # IAM Access Control
    iam_bindings = optional(list(object({
      member = string
      role   = string
      condition = optional(object({
        title       = string
        description = optional(string)
        expression  = string
      }))
    })))

    # Full IAM policy (use cautiously - replaces all bindings)
    iam_policy_data = optional(string)
  }))
  default = []

  validation {
    condition = alltrue([
      for secret in var.secrets :
      can(regex("^[a-zA-Z0-9_-]+$", secret.secret_id))
    ])
    error_message = "Secret IDs can only contain letters, numbers, hyphens, and underscores"
  }

  validation {
    condition = alltrue([
      for secret in var.secrets :
      lookup(secret, "replication_policy", "automatic") == "automatic" ||
      lookup(secret, "replication_policy", "automatic") == "user_managed"
    ])
    error_message = "Replication policy must be 'automatic' or 'user_managed'"
  }

  validation {
    condition = alltrue([
      for secret in var.secrets :
      lookup(secret, "secret_data", null) != null ||
      lookup(secret, "generate_random", false) == true ||
      lookup(secret, "manage_secret_data", true) == false
    ])
    error_message = "Each secret must have either secret_data, generate_random=true, or manage_secret_data=false"
  }
}

# Pub/Sub Topics for Change Notifications
variable "notification_topics" {
  description = "Pub/Sub topics for secret change notifications"
  type = list(object({
    name                       = string
    message_retention_duration = optional(string)
    schema_name                = optional(string)
    schema_encoding            = optional(string)
  }))
  default = []
}

# Labels
variable "labels" {
  description = "Labels to apply to all secrets and topics"
  type        = map(string)
  default     = {}
}

# Common Secret Presets
variable "create_database_url_secret" {
  description = "Create a secret for database URL"
  type        = bool
  default     = false
}

variable "database_url_value" {
  description = "Database URL value (if create_database_url_secret is true)"
  type        = string
  default     = ""
  sensitive   = true
}

variable "create_api_key_secret" {
  description = "Create a secret for API key with automatic generation"
  type        = bool
  default     = false
}

variable "api_key_length" {
  description = "Length of auto-generated API key"
  type        = number
  default     = 64
}

variable "create_jwt_secret" {
  description = "Create a secret for JWT signing key with automatic generation"
  type        = bool
  default     = false
}

variable "jwt_secret_length" {
  description = "Length of auto-generated JWT secret"
  type        = number
  default     = 64
}

# Rotation Defaults
variable "default_rotation_period" {
  description = "Default rotation period for secrets (seconds)"
  type        = string
  default     = null # No rotation by default

  validation {
    condition     = var.default_rotation_period == null || can(regex("^[0-9]+s$", var.default_rotation_period))
    error_message = "Rotation period must be in format: <number>s (e.g., '2592000s' for 30 days)"
  }
}

# Replication Defaults
variable "default_replication_policy" {
  description = "Default replication policy for secrets"
  type        = string
  default     = "automatic"

  validation {
    condition     = contains(["automatic", "user_managed"], var.default_replication_policy)
    error_message = "Replication policy must be 'automatic' or 'user_managed'"
  }
}

variable "default_kms_key_name" {
  description = "Default KMS key for CMEK encryption"
  type        = string
  default     = null
}

# Environment Helpers
variable "environment" {
  description = "Environment name (for generating secret names)"
  type        = string
  default     = ""

  validation {
    condition     = var.environment == "" || contains(["dev", "staging", "production"], var.environment)
    error_message = "Environment must be dev, staging, or production"
  }
}

# Service-specific Helpers
variable "service_name" {
  description = "Service name (for generating secret names)"
  type        = string
  default     = ""
}

# IAM Access Helpers
variable "grant_accessor_to_service_accounts" {
  description = "List of service account emails to grant secretAccessor role to all secrets"
  type        = list(string)
  default     = []
}

variable "grant_admin_to_users" {
  description = "List of user emails to grant secretAdmin role to all secrets"
  type        = list(string)
  default     = []
}
