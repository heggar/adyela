# Identity Platform Module - Main Configuration
# Configures Google Identity Platform with OAuth providers, MFA, and JWT tokens

# Enable required APIs
resource "google_project_service" "identity_toolkit" {
  project = var.project_id
  service = "identitytoolkit.googleapis.com"

  disable_on_destroy = false
}

resource "google_project_service" "identity_platform" {
  project = var.project_id
  service = "identityplatform.googleapis.com"

  disable_on_destroy = false
}

# Identity Platform Configuration
resource "google_identity_platform_config" "default" {
  project = var.project_id

  # Enable MFA if configured
  # Note: Only PHONE_SMS is supported via Terraform. TOTP must be configured in Firebase Console.
  dynamic "mfa" {
    for_each = var.enable_mfa && var.enable_sms_mfa ? [1] : []
    content {
      # Valid states: DISABLED, ENABLED, MANDATORY
      state = var.mfa_enforcement == "required" ? "MANDATORY" : "ENABLED"

      # Only PHONE_SMS provider is supported via Terraform
      enabled_providers = ["PHONE_SMS"]
    }
  }

  # Authorized domains for authentication
  authorized_domains = concat(
    var.authorized_domains,
    [
      "${var.project_id}.firebaseapp.com",
      "${var.project_id}.web.app"
    ]
  )

  # Sign-in configuration
  sign_in {
    allow_duplicate_emails = false

    # Email configuration
    dynamic "email" {
      for_each = var.enable_email_password ? [1] : []
      content {
        enabled           = true
        password_required = true
      }
    }

    # Anonymous sign-in (disabled for healthcare)
    anonymous {
      enabled = false
    }
  }

  # Blocking functions configuration (optional - can be added later)
  # Uncomment and configure when implementing custom authentication logic
  # blocking_functions {
  #   triggers {
  #     event_type = "beforeSignIn"
  #     function_uri = "https://us-central1-project-id.cloudfunctions.net/beforeSignIn"
  #   }
  # }

  # Client configuration
  client {
    permissions {
      disabled_user_signup    = false
      disabled_user_deletion  = false
    }
  }

  # Quota configuration (optional - commented out to use default quotas)
  # Uncomment and configure with start_time if custom quotas are needed
  # quota {
  #   sign_up_quota_config {
  #     quota          = 10000
  #     quota_duration = "86400s" # 24 hours
  #     start_time     = "2025-01-01T00:00:00Z"
  #   }
  # }

  depends_on = [
    google_project_service.identity_toolkit,
    google_project_service.identity_platform
  ]
}

# Identity Platform Tenant (for multi-tenancy)
resource "google_identity_platform_tenant" "default" {
  count        = var.enable_multi_tenancy ? 1 : 0
  project      = var.project_id
  display_name = "Adyela Healthcare Platform - ${title(var.environment)}"

  allow_password_signup = var.enable_email_password
  enable_email_link_signin = false

  # Note: MFA configuration for tenants is inherited from the project-level
  # Identity Platform config. Tenant-specific MFA is configured in Firebase Console.

  depends_on = [google_identity_platform_config.default]
}

# Service Account for API authentication
resource "google_service_account" "identity_platform_api" {
  project      = var.project_id
  account_id   = "identity-platform-api-${var.environment}"
  display_name = "Identity Platform API Service Account - ${title(var.environment)}"
  description  = "Service account for Identity Platform API authentication and token verification"
}

# IAM roles for service account
resource "google_project_iam_member" "identity_platform_admin" {
  project = var.project_id
  role    = "roles/firebaseauth.admin"
  member  = "serviceAccount:${google_service_account.identity_platform_api.email}"
}

resource "google_project_iam_member" "identity_platform_viewer" {
  project = var.project_id
  role    = "roles/firebaseauth.viewer"
  member  = "serviceAccount:${google_service_account.identity_platform_api.email}"
}

# Service account key for API authentication
resource "google_service_account_key" "identity_platform_api" {
  service_account_id = google_service_account.identity_platform_api.name

  # Store key in Secret Manager (referenced, not created here)
  depends_on = [google_service_account.identity_platform_api]
}

# Audit logging configuration for HIPAA compliance
resource "google_project_iam_audit_config" "identity_platform_audit" {
  count   = var.enable_audit_logging ? 1 : 0
  project = var.project_id
  service = "identitytoolkit.googleapis.com"

  audit_log_config {
    log_type = "ADMIN_READ"
  }

  audit_log_config {
    log_type = "DATA_READ"
  }

  audit_log_config {
    log_type = "DATA_WRITE"
  }
}

# Labels for resources
locals {
  common_labels = merge(
    {
      environment = var.environment
      managed_by  = "terraform"
      module      = "identity-platform"
      hipaa       = "true"
    },
    var.labels
  )
}
