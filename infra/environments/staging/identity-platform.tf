# Identity Platform Configuration for Staging Environment
# This configures Google Identity Platform with OAuth providers and MFA

# Get OAuth secrets from Secret Manager
# Note: Secrets must be created first using scripts/setup/setup-identity-secrets.sh

data "google_secret_manager_secret_version" "google_oauth_client_id" {
  project = var.project_id
  secret  = "oauth-google-client-id"
}

data "google_secret_manager_secret_version" "google_oauth_client_secret" {
  project = var.project_id
  secret  = "oauth-google-client-secret"
}

# Facebook OAuth secrets (commented out - to be created later)
# data "google_secret_manager_secret_version" "facebook_app_id" {
#   project = var.project_id
#   secret  = "oauth-facebook-app-id"
# }

# data "google_secret_manager_secret_version" "facebook_app_secret" {
#   project = var.project_id
#   secret  = "oauth-facebook-app-secret"
# }

# Microsoft OAuth secrets
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
  environment = "staging"
  region      = var.region

  # Enable authentication providers
  enable_email_password = true
  enable_google_oauth   = true
  enable_facebook       = false  # Disabled - placeholder credentials only
  enable_microsoft      = true   # Enabled with real credentials

  # OAuth credentials from Secret Manager
  google_oauth_client_id     = data.google_secret_manager_secret_version.google_oauth_client_id.secret_data
  google_oauth_client_secret = data.google_secret_manager_secret_version.google_oauth_client_secret.secret_data

  microsoft_client_id     = data.google_secret_manager_secret_version.microsoft_client_id.secret_data
  microsoft_client_secret = data.google_secret_manager_secret_version.microsoft_client_secret.secret_data

  # Facebook credentials (placeholder - not enabled)
  facebook_app_id     = "PLACEHOLDER"
  facebook_app_secret = "PLACEHOLDER"

  # Password policy for staging (relaxed for testing)
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
  log_retention_days   = 2555 # 7 years for HIPAA compliance

  # Labels
  labels = {
    application = "adyela"
    component   = "identity"
    environment = "staging"
    managed_by  = "terraform"
    hipaa       = "true"
  }
}

# Output Identity Platform configuration
output "identity_platform_tenant_id" {
  description = "Identity Platform tenant ID for multi-tenancy"
  value       = module.identity_platform.tenant_id
  sensitive   = false
}

output "identity_platform_service_account" {
  description = "Identity Platform service account email for API authentication"
  value       = module.identity_platform.service_account_email
  sensitive   = false
}

output "identity_platform_oauth_providers" {
  description = "List of configured OAuth providers"
  value       = module.identity_platform.oauth_providers_configured
  sensitive   = false
}

output "identity_platform_config" {
  description = "Complete Identity Platform configuration"
  value = {
    tenant_id              = module.identity_platform.tenant_id
    service_account_email  = module.identity_platform.service_account_email
    authorized_domains     = module.identity_platform.authorized_domains
    mfa_enabled            = module.identity_platform.mfa_enabled
    oauth_providers        = module.identity_platform.oauth_providers_configured
    audit_logging_enabled  = module.identity_platform.audit_logging_enabled
  }
  sensitive = false
}
