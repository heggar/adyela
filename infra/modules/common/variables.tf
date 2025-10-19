# Common Labels Module Variables

# Required Variables

variable "environment" {
  description = "Environment name (development, staging, production)"
  type        = string

  validation {
    condition     = contains(["development", "staging", "production"], var.environment)
    error_message = "Environment must be one of: development, staging, production"
  }
}

variable "project_name" {
  description = "Project name (e.g., adyela)"
  type        = string
  default     = "adyela"
}

variable "product_name" {
  description = "Product name (e.g., adyela-healthcare)"
  type        = string
  default     = "adyela-healthcare"
}

variable "team" {
  description = "Team responsible for the resource (e.g., platform, backend, frontend)"
  type        = string
  default     = "platform"

  validation {
    condition     = contains(["platform", "backend", "frontend", "data", "devops", "security"], var.team)
    error_message = "Team must be one of: platform, backend, frontend, data, devops, security"
  }
}

variable "owner" {
  description = "Owner/maintainer of the resource (e.g., john_doe)"
  type        = string
  default     = "platform-team"
}

# Cost Management

variable "cost_center" {
  description = "Cost center for billing attribution"
  type        = string
  default     = "engineering"
}

variable "billing_id" {
  description = "Billing account ID or identifier"
  type        = string
  default     = "adyela-eng"
}

# Application Metadata (Optional)

variable "application" {
  description = "Application name (e.g., api, web, mobile)"
  type        = string
  default     = null
}

variable "component" {
  description = "Component within application (e.g., auth, appointments, analytics)"
  type        = string
  default     = null
}

variable "service" {
  description = "Service name (e.g., adyela-api-staging)"
  type        = string
  default     = null
}

variable "tier" {
  description = "Service tier (e.g., frontend, backend, database, cache)"
  type        = string
  default     = null

  validation {
    condition     = var.tier == null || contains(["frontend", "backend", "database", "cache", "queue", "storage"], var.tier)
    error_message = "Tier must be one of: frontend, backend, database, cache, queue, storage"
  }
}

variable "app_version" {
  description = "Application/resource version (e.g., v1_0_0)"
  type        = string
  default     = null
}

# Compliance and Security (Optional)

variable "compliance_required" {
  description = "Compliance requirements (e.g., hipaa, gdpr, sox)"
  type        = string
  default     = "hipaa"
}

variable "data_classification" {
  description = "Data classification level (e.g., public, internal, confidential, restricted)"
  type        = string
  default     = "confidential"

  validation {
    condition     = var.data_classification == null || contains(["public", "internal", "confidential", "restricted"], var.data_classification)
    error_message = "Data classification must be one of: public, internal, confidential, restricted"
  }
}

variable "hipaa_scope" {
  description = "Whether resource contains PHI (yes, no, indirect)"
  type        = string
  default     = "yes"

  validation {
    condition     = var.hipaa_scope == null || contains(["yes", "no", "indirect"], var.hipaa_scope)
    error_message = "HIPAA scope must be one of: yes, no, indirect"
  }
}

# Operational (Optional)

variable "backup_policy" {
  description = "Backup policy (e.g., daily, weekly, none)"
  type        = string
  default     = null
}

variable "disaster_recovery" {
  description = "Disaster recovery tier (e.g., critical, high, medium, low)"
  type        = string
  default     = null

  validation {
    condition     = var.disaster_recovery == null || contains(["critical", "high", "medium", "low"], var.disaster_recovery)
    error_message = "Disaster recovery must be one of: critical, high, medium, low"
  }
}

variable "high_availability" {
  description = "High availability requirement (true/false)"
  type        = string
  default     = null
}

variable "contact_email" {
  description = "Contact email for the resource owner"
  type        = string
  default     = null
}

# Custom Labels and Tags

variable "custom_labels" {
  description = "Additional custom labels to apply to resources"
  type        = map(string)
  default     = {}
}

variable "custom_tags" {
  description = "Additional custom tags to apply to resources (for resources that support tags)"
  type        = list(string)
  default     = []
}
