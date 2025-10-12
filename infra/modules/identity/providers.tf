# Identity Platform Module - Authentication Providers Configuration
# Configures OAuth providers (Google, Facebook, Microsoft) for Identity Platform

# Google OAuth Provider
resource "google_identity_platform_default_supported_idp_config" "google" {
  count         = var.enable_google_oauth ? 1 : 0
  project       = var.project_id
  idp_id        = "google.com"
  enabled       = true
  client_id     = var.google_oauth_client_id
  client_secret = var.google_oauth_client_secret

  depends_on = [
    google_identity_platform_config.default
  ]
}

# Facebook OAuth Provider
resource "google_identity_platform_default_supported_idp_config" "facebook" {
  count         = var.enable_facebook ? 1 : 0
  project       = var.project_id
  idp_id        = "facebook.com"
  enabled       = true
  client_id     = var.facebook_app_id
  client_secret = var.facebook_app_secret

  depends_on = [
    google_identity_platform_config.default
  ]
}

# Microsoft OAuth Provider
resource "google_identity_platform_default_supported_idp_config" "microsoft" {
  count         = var.enable_microsoft ? 1 : 0
  project       = var.project_id
  idp_id        = "microsoft.com"
  enabled       = true
  client_id     = var.microsoft_client_id
  client_secret = var.microsoft_client_secret

  depends_on = [
    google_identity_platform_config.default
  ]
}

# OAuth Redirect URIs Configuration
locals {
  oauth_redirect_uris = [
    for domain in var.authorized_domains :
    domain == "localhost" ? "http://localhost:9099/__/auth/handler" : "https://${domain}/__/auth/handler"
  ]
}

# Output OAuth provider configuration
output "oauth_providers_configured" {
  description = "List of configured OAuth providers"
  value = compact([
    var.enable_google_oauth ? "google.com" : "",
    var.enable_facebook ? "facebook.com" : "",
    var.enable_microsoft ? "microsoft.com" : ""
  ])
}

output "oauth_redirect_uris" {
  description = "OAuth redirect URIs for configured providers"
  value       = local.oauth_redirect_uris
}
