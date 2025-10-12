# Example Terraform Variables for Identity Platform Module
# Copy this file to terraform.tfvars and update with your values

# === Required Variables ===

project_id  = "adyela-staging"
environment = "staging"
region      = "us-central1"

# === Authentication Providers ===

# Enable/disable providers
enable_email_password = true
enable_google_oauth   = true
enable_facebook       = true
enable_microsoft      = true

# OAuth Credentials (use Secret Manager in production)
# Example: data.google_secret_manager_secret_version.google_oauth_client_id.secret_data
google_oauth_client_id     = "123456789-abcdefghijklmnop.apps.googleusercontent.com"
google_oauth_client_secret = "GOCSPX-your-client-secret"
facebook_app_id            = "1234567890123456"
facebook_app_secret        = "your-facebook-app-secret"
microsoft_client_id        = "12345678-1234-1234-1234-123456789012"
microsoft_client_secret    = "your-microsoft-client-secret"

# === Password Policy Configuration ===

password_policy = {
  min_length           = 12
  require_uppercase    = true
  require_lowercase    = true
  require_numeric      = true
  require_special_char = true
  max_failed_attempts  = 5
  lockout_duration     = "15m"
}

# === MFA Configuration ===

enable_mfa      = true
mfa_enforcement = "optional" # Options: "optional", "required", "required_for_high_risk"
enable_totp_mfa = true
enable_sms_mfa  = true

# === JWT Token Configuration ===

jwt_token_expiration         = 3600    # 1 hour
jwt_refresh_token_expiration = 2592000 # 30 days
jwt_custom_claims            = true

# === Multi-Tenancy Configuration ===

enable_multi_tenancy = true

# === User Management Configuration ===

enable_email_verification = true
enable_password_reset     = true
user_session_timeout      = 3600 # 1 hour

# === Authorized Domains ===

authorized_domains = [
  "localhost",
  "staging.adyela.care"
]

# === HIPAA Compliance Settings ===

enable_audit_logging = true
log_retention_days   = 2555 # 7 years for HIPAA compliance

# === Resource Labels ===

labels = {
  application = "adyela"
  component   = "identity"
  owner       = "infrastructure-team"
  cost_center = "healthcare-platform"
}

# === Production Configuration Example ===

# For production, use stricter settings:
# password_policy = {
#   min_length             = 14
#   require_uppercase      = true
#   require_lowercase      = true
#   require_numeric        = true
#   require_special_char   = true
#   max_failed_attempts    = 3
#   lockout_duration       = "30m"
# }
#
# mfa_enforcement = "required"
# jwt_token_expiration = 1800 # 30 minutes
#
# authorized_domains = ["adyela.care"]
