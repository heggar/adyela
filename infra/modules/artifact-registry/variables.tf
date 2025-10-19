# Artifact Registry Module Variables

variable "project_id" {
  description = "The GCP project ID"
  type        = string
}

variable "location" {
  description = "The location of the repository (e.g., us-central1, us, europe)"
  type        = string
  default     = "us-central1"
}

variable "repository_id" {
  description = "The ID of the repository"
  type        = string
}

variable "description" {
  description = "Description of the repository"
  type        = string
  default     = ""
}

variable "format" {
  description = "The format of packages stored in the repository (DOCKER, MAVEN, NPM, PYTHON, APT, YUM, GENERIC)"
  type        = string
  default     = "DOCKER"

  validation {
    condition     = contains(["DOCKER", "MAVEN", "NPM", "PYTHON", "APT", "YUM", "GENERIC"], var.format)
    error_message = "Format must be one of: DOCKER, MAVEN, NPM, PYTHON, APT, YUM, GENERIC"
  }
}

variable "environment" {
  description = "Environment (staging, production, development)"
  type        = string
}

variable "labels" {
  description = "Additional labels for the repository"
  type        = map(string)
  default     = {}
}

variable "cleanup_policies" {
  description = "Cleanup policies to manage repository storage"
  type = list(object({
    id     = string
    action = string
    condition = optional(object({
      tag_state             = optional(string)
      tag_prefixes          = optional(list(string))
      older_than            = optional(string)
      newer_than            = optional(string)
      package_name_prefixes = optional(list(string))
      version_name_prefixes = optional(list(string))
    }))
    most_recent_versions = optional(object({
      keep_count            = optional(number)
      package_name_prefixes = optional(list(string))
    }))
  }))
  default = []
}

variable "immutable_tags" {
  description = "If true, tags are immutable in the repository (recommended for production)"
  type        = bool
  default     = false
}

variable "kms_key_name" {
  description = "The KMS key name for encryption (optional)"
  type        = string
  default     = null
}

variable "mode" {
  description = "The mode of the repository (STANDARD_REPOSITORY, VIRTUAL_REPOSITORY, REMOTE_REPOSITORY)"
  type        = string
  default     = "STANDARD_REPOSITORY"

  validation {
    condition     = contains(["STANDARD_REPOSITORY", "VIRTUAL_REPOSITORY", "REMOTE_REPOSITORY"], var.mode)
    error_message = "Mode must be one of: STANDARD_REPOSITORY, VIRTUAL_REPOSITORY, REMOTE_REPOSITORY"
  }
}

variable "reader_members" {
  description = "List of members who can read from the repository (e.g., serviceAccount:xxx@xxx.iam.gserviceaccount.com)"
  type        = list(string)
  default     = []
}

variable "writer_members" {
  description = "List of members who can write to the repository (e.g., serviceAccount:xxx@xxx.iam.gserviceaccount.com)"
  type        = list(string)
  default     = []
}

variable "create_cicd_service_account" {
  description = "Whether to create a service account for CI/CD pipelines"
  type        = bool
  default     = false
}

variable "grant_storage_admin" {
  description = "Whether to grant storage admin to CI/CD service account (needed for cleanup)"
  type        = bool
  default     = false
}
