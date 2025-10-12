# Identity Platform Module - Input Variables

variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, staging, production)"
  type        = string
  validation {
    condition     = contains(["dev", "staging", "production"], var.environment)
    error_message = "Environment must be dev, staging, or production."
  }
}

variable "region" {
  description = "GCP region for Identity Platform configuration"
  type        = string
  default     = "us-central1"
}

# Authentication Providers Configuration
variable "enable_email_password" {
  description = "Enable email/password authentication provider"
  type        = bool
  default     = true
}

variable "enable_google_oauth" {
  description = "Enable Google OAuth authentication provider"
  type        = bool
  default     = true
}

variable "google_oauth_client_id" {
  description = "Google OAuth 2.0 Client ID"
  type        = string
  sensitive   = true
  default     = ""
}

variable "google_oauth_client_secret" {
  description = "Google OAuth 2.0 Client Secret"
  type        = string
  sensitive   = true
  default     = ""
}

variable "enable_facebook" {
  description = "Enable Facebook authentication provider"
  type        = bool
  default     = true
}

variable "facebook_app_id" {
  description = "Facebook App ID"
  type        = string
  sensitive   = true
  default     = ""
}

variable "facebook_app_secret" {
  description = "Facebook App Secret"
  type        = string
  sensitive   = true
  default     = ""
}

variable "enable_microsoft" {
  description = "Enable Microsoft authentication provider"
  type        = bool
  default     = true
}

variable "microsoft_client_id" {
  description = "Microsoft Client ID"
  type        = string
  sensitive   = true
  default     = ""
}

variable "microsoft_client_secret" {
  description = "Microsoft Client Secret"
  type        = string
  sensitive   = true
  default     = ""
}

# Password Policy Configuration
variable "password_policy" {
  description = "Password policy configuration for email/password authentication"
  type = object({
    min_length           = number
    require_uppercase    = bool
    require_lowercase    = bool
    require_numeric      = bool
    require_special_char = bool
    max_failed_attempts  = number
    lockout_duration     = string
  })
  default = {
    min_length           = 12
    require_uppercase    = true
    require_lowercase    = true
    require_numeric      = true
    require_special_char = true
    max_failed_attempts  = 5
    lockout_duration     = "15m"
  }
}

# MFA Configuration
variable "enable_mfa" {
  description = "Enable Multi-Factor Authentication"
  type        = bool
  default     = true
}

variable "mfa_enforcement" {
  description = "MFA enforcement level (optional, required, required_for_high_risk)"
  type        = string
  default     = "optional"
  validation {
    condition     = contains(["optional", "required", "required_for_high_risk"], var.mfa_enforcement)
    error_message = "MFA enforcement must be optional, required, or required_for_high_risk."
  }
}

variable "enable_totp_mfa" {
  description = "Enable TOTP (Time-based One-Time Password) MFA"
  type        = bool
  default     = true
}

variable "enable_sms_mfa" {
  description = "Enable SMS-based MFA"
  type        = bool
  default     = true
}

# JWT Token Configuration
variable "jwt_token_expiration" {
  description = "JWT token expiration time in seconds"
  type        = number
  default     = 3600 # 1 hour
  validation {
    condition     = var.jwt_token_expiration >= 300 && var.jwt_token_expiration <= 86400
    error_message = "JWT token expiration must be between 5 minutes (300s) and 24 hours (86400s)."
  }
}

variable "jwt_refresh_token_expiration" {
  description = "JWT refresh token expiration time in seconds"
  type        = number
  default     = 2592000 # 30 days
}

variable "jwt_custom_claims" {
  description = "Enable custom JWT claims (tenant_id, role, permissions)"
  type        = bool
  default     = true
}

# Multi-Tenancy Configuration
variable "enable_multi_tenancy" {
  description = "Enable multi-tenancy support with tenant isolation"
  type        = bool
  default     = true
}

# User Management Configuration
variable "enable_email_verification" {
  description = "Require email verification for new users"
  type        = bool
  default     = true
}

variable "enable_password_reset" {
  description = "Enable password reset functionality"
  type        = bool
  default     = true
}

variable "user_session_timeout" {
  description = "User session timeout in seconds"
  type        = number
  default     = 3600 # 1 hour
}

# Authorized Domains
variable "authorized_domains" {
  description = "List of authorized domains for authentication"
  type        = list(string)
  default     = ["localhost"]
}

# Labels for resource organization
variable "labels" {
  description = "Labels to apply to resources"
  type        = map(string)
  default     = {}
}

# HIPAA Compliance Settings
variable "enable_audit_logging" {
  description = "Enable comprehensive audit logging for HIPAA compliance"
  type        = bool
  default     = true
}

variable "log_retention_days" {
  description = "Number of days to retain audit logs (HIPAA requires 7 years = 2555 days)"
  type        = number
  default     = 2555
}
