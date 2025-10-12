# Example Identity Platform Configuration for Staging Environment
# This file demonstrates how to use the identity module
# Uncomment and configure with actual values to deploy

/*
# Get OAuth secrets from Secret Manager
data "google_secret_manager_secret_version" "google_oauth_client_id" {
  project = var.project_id
  secret  = "oauth-google-client-id"
}

data "google_secret_manager_secret_version" "google_oauth_client_secret" {
  project = var.project_id
  secret  = "oauth-google-client-secret"
}

data "google_secret_manager_secret_version" "facebook_app_id" {
  project = var.project_id
  secret  = "oauth-facebook-app-id"
}

data "google_secret_manager_secret_version" "facebook_app_secret" {
  project = var.project_id
  secret  = "oauth-facebook-app-secret"
}

data "google_secret_manager_secret_version" "microsoft_client_id" {
  project = var.project_id
  secret  = "oauth-microsoft-client-id"
}

data "google_secret_manager_secret_version" "microsoft_client_secret" {
  project = var.project_id
  secret  = "oauth-microsoft-client-secret"
}

# Deploy Identity Platform module
module "identity_platform" {
  source = "../../modules/identity"

  project_id  = var.project_id
  environment = var.environment
  region      = var.region

  # Enable authentication providers
  enable_email_password = true
  enable_google_oauth   = true
  enable_facebook       = true
  enable_microsoft      = true

  # OAuth credentials from Secret Manager
  google_oauth_client_id     = data.google_secret_manager_secret_version.google_oauth_client_id.secret_data
  google_oauth_client_secret = data.google_secret_manager_secret_version.google_oauth_client_secret.secret_data
  facebook_app_id            = data.google_secret_manager_secret_version.facebook_app_id.secret_data
  facebook_app_secret        = data.google_secret_manager_secret_version.facebook_app_secret.secret_data
  microsoft_client_id        = data.google_secret_manager_secret_version.microsoft_client_id.secret_data
  microsoft_client_secret    = data.google_secret_manager_secret_version.microsoft_client_secret.secret_data

  # Password policy for staging
  password_policy = {
    min_length             = 12
    require_uppercase      = true
    require_lowercase      = true
    require_numeric        = true
    require_special_char   = true
    max_failed_attempts    = 5
    lockout_duration       = "15m"
  }

  # MFA configuration (optional for staging)
  enable_mfa      = true
  mfa_enforcement = "optional"
  enable_totp_mfa = true
  enable_sms_mfa  = true

  # JWT token configuration
  jwt_token_expiration         = 3600    # 1 hour
  jwt_refresh_token_expiration = 2592000 # 30 days
  jwt_custom_claims            = true

  # Multi-tenancy support
  enable_multi_tenancy = true

  # User management
  enable_email_verification = true
  enable_password_reset     = true
  user_session_timeout      = 3600

  # Authorized domains
  authorized_domains = [
    "localhost",
    "staging.adyela.care"
  ]

  # HIPAA compliance
  enable_audit_logging = true
  log_retention_days   = 2555 # 7 years

  # Labels
  labels = {
    application = "adyela"
    component   = "identity"
    environment = var.environment
    managed_by  = "terraform"
  }
}

# Output Identity Platform configuration
output "identity_platform_tenant_id" {
  description = "Identity Platform tenant ID"
  value       = module.identity_platform.tenant_id
}

output "identity_platform_service_account" {
  description = "Identity Platform service account email"
  value       = module.identity_platform.service_account_email
}

output "identity_platform_oauth_providers" {
  description = "Configured OAuth providers"
  value       = module.identity_platform.oauth_providers_configured
}
*/
