# Identity Platform Module - Outputs

output "identity_platform_config_name" {
  description = "Name of the Identity Platform configuration"
  value       = google_identity_platform_config.default.name
}

output "tenant_id" {
  description = "Identity Platform tenant ID (if multi-tenancy is enabled)"
  value       = var.enable_multi_tenancy ? google_identity_platform_tenant.default[0].name : null
}

output "tenant_display_name" {
  description = "Display name of the Identity Platform tenant"
  value       = var.enable_multi_tenancy ? google_identity_platform_tenant.default[0].display_name : null
}

output "service_account_email" {
  description = "Email of the Identity Platform API service account"
  value       = google_service_account.identity_platform_api.email
}

output "service_account_id" {
  description = "ID of the Identity Platform API service account"
  value       = google_service_account.identity_platform_api.account_id
}

output "service_account_unique_id" {
  description = "Unique ID of the Identity Platform API service account"
  value       = google_service_account.identity_platform_api.unique_id
}

output "service_account_key_name" {
  description = "Name of the service account key (store in Secret Manager)"
  value       = google_service_account_key.identity_platform_api.name
  sensitive   = true
}

output "authorized_domains" {
  description = "List of authorized domains for authentication"
  value       = google_identity_platform_config.default.authorized_domains
}

output "mfa_enabled" {
  description = "Whether MFA is enabled"
  value       = var.enable_mfa
}

output "mfa_providers" {
  description = "List of enabled MFA providers"
  value = concat(
    var.enable_totp_mfa ? ["TOTP"] : [],
    var.enable_sms_mfa ? ["SMS"] : []
  )
}

output "jwt_token_expiration" {
  description = "JWT token expiration time in seconds"
  value       = var.jwt_token_expiration
}

output "jwt_refresh_token_expiration" {
  description = "JWT refresh token expiration time in seconds"
  value       = var.jwt_refresh_token_expiration
}

output "authentication_providers" {
  description = "List of enabled authentication providers"
  value = {
    email_password = var.enable_email_password
    google_oauth   = var.enable_google_oauth
    facebook       = var.enable_facebook
    microsoft      = var.enable_microsoft
  }
}

output "password_policy" {
  description = "Configured password policy"
  value       = var.password_policy
  sensitive   = true
}

output "audit_logging_enabled" {
  description = "Whether audit logging is enabled for HIPAA compliance"
  value       = var.enable_audit_logging
}

output "log_retention_days" {
  description = "Number of days to retain audit logs"
  value       = var.log_retention_days
}

output "multi_tenancy_enabled" {
  description = "Whether multi-tenancy is enabled"
  value       = var.enable_multi_tenancy
}
