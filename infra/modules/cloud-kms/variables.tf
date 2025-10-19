# Cloud KMS Module Variables

variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "key_rings" {
  description = "List of key rings to create"
  type = list(object({
    name     = string
    location = string
  }))
  default = []
}

variable "crypto_keys" {
  description = "List of crypto keys to create"
  type = list(object({
    name             = string
    key_ring         = string
    purpose          = optional(string)
    rotation_period  = optional(string)
    algorithm        = optional(string)
    protection_level = optional(string)
    prevent_destroy  = optional(bool)
    labels           = optional(map(string))
    iam_bindings = optional(list(object({
      member = string
      role   = string
    })))
  }))
  default = []
}

variable "labels" {
  description = "Labels to apply to all resources"
  type        = map(string)
  default     = {}
}
