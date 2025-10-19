# IAM Module Variables

variable "project_id" {
  description = "The GCP project ID"
  type        = string
}

variable "org_id" {
  description = "The GCP organization ID (optional, for org-level custom roles)"
  type        = string
  default     = null
}

# Service Accounts
variable "service_accounts" {
  description = "List of service accounts to create with their configurations"
  type = list(object({
    account_id   = string
    display_name = optional(string)
    description  = optional(string)
    disabled     = optional(bool)

    # Project-level roles to assign to this service account
    project_roles = optional(list(string))

    # IAM bindings for this service account (who can impersonate it)
    iam_bindings = optional(list(object({
      member = string
      role   = string
      condition = optional(object({
        title       = string
        description = optional(string)
        expression  = string
      }))
    })))

    # Full IAM policy data (use cautiously - replaces all bindings)
    iam_policy_data = optional(string)

    # Key creation (NOT RECOMMENDED - use Workload Identity)
    create_key      = optional(bool)
    key_algorithm   = optional(string)
    public_key_type = optional(string)
  }))
  default = []

  validation {
    condition = alltrue([
      for sa in var.service_accounts :
      can(regex("^[a-z]([a-z0-9-]{4,28}[a-z0-9])$", sa.account_id))
    ])
    error_message = "Service account IDs must be 6-30 characters, start with lowercase letter, contain only lowercase letters, numbers, and hyphens"
  }
}

# Custom IAM Roles (Project-level)
variable "custom_roles" {
  description = "List of custom IAM roles to create at project level"
  type = list(object({
    role_id     = string
    title       = string
    description = optional(string)
    permissions = list(string)
    stage       = optional(string)
  }))
  default = []

  validation {
    condition = alltrue([
      for role in var.custom_roles :
      can(regex("^[a-zA-Z0-9_\\.]{3,64}$", role.role_id))
    ])
    error_message = "Custom role IDs must be 3-64 characters, contain only letters, numbers, periods, and underscores"
  }
}

# Custom IAM Roles (Organization-level)
variable "org_custom_roles" {
  description = "List of custom IAM roles to create at organization level"
  type = list(object({
    role_id     = string
    title       = string
    description = optional(string)
    permissions = list(string)
    stage       = optional(string)
  }))
  default = []
}

# Project IAM Members (non-service accounts)
variable "project_iam_members" {
  description = "Map of IAM members to grant project-level roles (users, groups, domains)"
  type = map(object({
    roles = list(string)
    condition = optional(object({
      title       = string
      description = optional(string)
      expression  = string
    }))
  }))
  default = {}

  validation {
    condition = alltrue([
      for member, config in var.project_iam_members :
      can(regex("^(user|group|domain|serviceAccount):", member))
    ])
    error_message = "IAM members must be in format: user:email, group:email, domain:example.com, or serviceAccount:email"
  }
}

# Workload Identity (GKE/Cloud Run)
variable "workload_identity_bindings" {
  description = "Bindings for Workload Identity (Kubernetes service accounts to GCP service accounts)"
  type = list(object({
    service_account_id  = string
    namespace           = string
    k8s_service_account = string
  }))
  default = []
}

# Service Account Keys
variable "create_keys" {
  description = "Enable creation of service account keys (NOT RECOMMENDED - use Workload Identity or federation)"
  type        = bool
  default     = false
}

# Audit Logging
variable "enable_audit_logs" {
  description = "Enable Cloud Audit Logs for IAM operations"
  type        = bool
  default     = true
}

variable "audit_log_services" {
  description = "GCP services to enable audit logging for"
  type        = list(string)
  default = [
    "allServices" # All services
  ]
}

variable "audit_log_configs" {
  description = "Audit log configurations"
  type = list(object({
    log_type         = string
    exempted_members = optional(list(string))
  }))
  default = [
    {
      log_type         = "ADMIN_READ"
      exempted_members = []
    },
    {
      log_type         = "DATA_READ"
      exempted_members = []
    },
    {
      log_type         = "DATA_WRITE"
      exempted_members = []
    }
  ]

  validation {
    condition = alltrue([
      for config in var.audit_log_configs :
      contains(["ADMIN_READ", "DATA_READ", "DATA_WRITE"], config.log_type)
    ])
    error_message = "Audit log type must be ADMIN_READ, DATA_READ, or DATA_WRITE"
  }
}

# Labels
variable "labels" {
  description = "Labels to apply to service accounts"
  type        = map(string)
  default     = {}
}

# Common Service Account Presets
variable "enable_cloud_run_sa" {
  description = "Create a service account for Cloud Run services"
  type        = bool
  default     = false
}

variable "cloud_run_sa_roles" {
  description = "Roles to assign to Cloud Run service account"
  type        = list(string)
  default = [
    "roles/cloudsql.client",
    "roles/secretmanager.secretAccessor",
    "roles/firestore.user"
  ]
}

variable "enable_cloud_build_sa" {
  description = "Create a service account for Cloud Build"
  type        = bool
  default     = false
}

variable "cloud_build_sa_roles" {
  description = "Roles to assign to Cloud Build service account"
  type        = list(string)
  default = [
    "roles/artifactregistry.writer",
    "roles/run.developer",
    "roles/iam.serviceAccountUser"
  ]
}

variable "enable_github_actions_sa" {
  description = "Create a service account for GitHub Actions with Workload Identity Federation"
  type        = bool
  default     = false
}

variable "github_actions_sa_roles" {
  description = "Roles to assign to GitHub Actions service account"
  type        = list(string)
  default = [
    "roles/artifactregistry.writer",
    "roles/cloudbuild.builds.editor",
    "roles/run.developer",
    "roles/iam.serviceAccountUser"
  ]
}

variable "github_repository" {
  description = "GitHub repository for Workload Identity Federation (format: owner/repo)"
  type        = string
  default     = ""
}

# Least Privilege Helpers
variable "environment" {
  description = "Environment name (for generating service account names)"
  type        = string
  default     = ""

  validation {
    condition     = var.environment == "" || contains(["dev", "staging", "production"], var.environment)
    error_message = "Environment must be dev, staging, or production"
  }
}

variable "service_name" {
  description = "Service name (for generating service account names)"
  type        = string
  default     = ""
}
