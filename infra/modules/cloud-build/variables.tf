# Cloud Build Module Variables

variable "project_id" {
  description = "The GCP project ID"
  type        = string
}

variable "trigger_name" {
  description = "The name of the Cloud Build trigger"
  type        = string
}

variable "description" {
  description = "Description of the Cloud Build trigger"
  type        = string
  default     = ""
}

variable "location" {
  description = "The location of the Cloud Build trigger (e.g., us-central1, global)"
  type        = string
  default     = "global"
}

variable "environment" {
  description = "Environment (staging, production, development)"
  type        = string
}

variable "tags" {
  description = "Additional tags for the Cloud Build trigger"
  type        = list(string)
  default     = []
}

# GitHub Configuration
variable "github_config" {
  description = "GitHub repository configuration"
  type = object({
    owner     = string
    repo_name = string
    push_config = optional(object({
      branch       = optional(string)
      tag          = optional(string)
      invert_regex = optional(bool)
    }))
    pull_request_config = optional(object({
      branch          = string
      comment_control = optional(string)
      invert_regex    = optional(bool)
    }))
  })
  default = null
}

# Build Configuration
variable "build_config_file" {
  description = "Path to cloudbuild.yaml file in the repository (relative to repo root)"
  type        = string
  default     = null
}

variable "inline_build_config" {
  description = "Inline build configuration (alternative to cloudbuild.yaml)"
  type = object({
    steps = list(object({
      name       = string
      args       = optional(list(string))
      env        = optional(list(string))
      id         = optional(string)
      wait_for   = optional(list(string))
      entrypoint = optional(string)
      dir        = optional(string)
      secret_env = optional(list(string))
    }))
    substitutions = optional(map(string))
    timeout       = optional(string)
    images        = optional(list(string))
    artifacts = optional(object({
      images = optional(list(string))
      objects = optional(object({
        location = string
        paths    = list(string)
      }))
    }))
    options = optional(object({
      machine_type            = optional(string)
      disk_size_gb            = optional(number)
      substitution_option     = optional(string)
      dynamic_substitutions   = optional(bool)
      log_streaming_option    = optional(string)
      logging                 = optional(string)
      requested_verify_option = optional(string)
    }))
  })
  default = null

  validation {
    condition     = var.inline_build_config != null || var.build_config_file != null
    error_message = "Either inline_build_config or build_config_file must be provided"
  }
}

variable "substitutions" {
  description = "Substitutions (variables) available to the build"
  type        = map(string)
  default     = {}
}

variable "included_files" {
  description = "Only trigger builds when files matching these patterns change"
  type        = list(string)
  default     = []
}

variable "ignored_files" {
  description = "Do not trigger builds when only files matching these patterns change"
  type        = list(string)
  default     = []
}

variable "require_approval" {
  description = "Whether builds require manual approval before running"
  type        = bool
  default     = false
}

variable "disabled" {
  description = "Whether the trigger is disabled"
  type        = bool
  default     = false
}

# Service Account Configuration
variable "create_service_account" {
  description = "Whether to create a dedicated service account for this build trigger"
  type        = bool
  default     = false
}

variable "service_account_email" {
  description = "Email of service account to use for builds (if not creating one)"
  type        = string
  default     = null
}

variable "grant_artifact_registry_access" {
  description = "Grant service account permission to push to Artifact Registry"
  type        = bool
  default     = true
}

variable "grant_cloud_run_access" {
  description = "Grant service account permission to deploy to Cloud Run"
  type        = bool
  default     = false
}

variable "grant_secret_access" {
  description = "Grant service account permission to access Secret Manager"
  type        = bool
  default     = false
}

variable "cloud_run_service_account" {
  description = "Cloud Run service account that this build SA needs to act as (full resource ID)"
  type        = string
  default     = null
}

variable "custom_roles" {
  description = "Map of custom role names to grant to the service account"
  type        = map(string)
  default     = {}
}
