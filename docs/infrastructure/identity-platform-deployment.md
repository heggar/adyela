# Identity Platform Deployment Guide

This guide provides step-by-step instructions for deploying Google Identity Platform using the Terraform module created for the Adyela healthcare platform.

## Overview

The Identity Platform module provides:

- **OAuth Authentication**: Google, Facebook, Microsoft
- **Multi-Factor Authentication (MFA)**: TOTP and SMS
- **JWT Custom Claims**: Multi-tenant support
- **HIPAA Compliance**: 7-year audit log retention
- **Service Account**: API authentication

## Prerequisites

### 1. GCP Project Setup

```bash
# Set project ID
export PROJECT_ID="adyela-staging"
gcloud config set project $PROJECT_ID

# Enable required APIs
gcloud services enable identitytoolkit.googleapis.com
gcloud services enable identityplatform.googleapis.com
gcloud services enable secretmanager.googleapis.com
```

### 2. OAuth Provider Configuration

#### Google OAuth

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Navigate to "APIs & Services" > "Credentials"
3. Create OAuth 2.0 Client ID:
   - Application type: Web application
   - Name: Adyela OAuth
   - Authorized JavaScript origins:
     - `http://localhost:5173`
     - `https://staging.adyela.care`
   - Authorized redirect URIs:
     - `http://localhost:9099/__/auth/handler`
     - `https://staging.adyela.care/__/auth/handler`

4. Store credentials in Secret Manager:

```bash
# Google OAuth credentials
echo -n "YOUR_GOOGLE_CLIENT_ID" | gcloud secrets create oauth-google-client-id --data-file=-
echo -n "YOUR_GOOGLE_CLIENT_SECRET" | gcloud secrets create oauth-google-client-secret --data-file=-
```

#### Facebook OAuth

1. Go to [Facebook Developers](https://developers.facebook.com/)
2. Create a new app
3. Add "Facebook Login" product
4. Configure OAuth redirect URIs (same as Google)
5. Store credentials:

```bash
echo -n "YOUR_FACEBOOK_APP_ID" | gcloud secrets create oauth-facebook-app-id --data-file=-
echo -n "YOUR_FACEBOOK_APP_SECRET" | gcloud secrets create oauth-facebook-app-secret --data-file=-
```

#### Microsoft OAuth

1. Go to [Azure Portal](https://portal.azure.com/)
2. Navigate to "App registrations"
3. Register new application
4. Add redirect URIs (same as Google)
5. Add API permission: Microsoft Graph > User.Read
6. Store credentials:

```bash
echo -n "YOUR_MICROSOFT_CLIENT_ID" | gcloud secrets create oauth-microsoft-client-id --data-file=-
echo -n "YOUR_MICROSOFT_CLIENT_SECRET" | gcloud secrets create oauth-microsoft-client-secret --data-file=-
```

## Deployment Steps

### Step 1: Configure Terraform Variables

Edit `infra/environments/staging/terraform.tfvars`:

```hcl
project_id  = "adyela-staging"
environment = "staging"
region      = "us-central1"

# Identity Platform will be configured via module
```

### Step 2: Create Identity Platform Configuration

Create a new file `infra/environments/staging/identity-platform.tf`:

```hcl
# Get OAuth secrets from Secret Manager
data "google_secret_manager_secret_version" "google_oauth_client_id" {
  project = var.project_id
  secret  = "oauth-google-client-id"
}

data "google_secret_manager_secret_version" "google_oauth_client_secret" {
  project = var.project_id
  secret  = "oauth-google-client-secret"
}

# ... (add other secrets)

# Deploy Identity Platform
module "identity_platform" {
  source = "../../modules/identity"

  project_id  = var.project_id
  environment = var.environment
  region      = var.region

  # Enable providers
  enable_email_password = true
  enable_google_oauth   = true
  enable_facebook       = true
  enable_microsoft      = true

  # OAuth credentials
  google_oauth_client_id     = data.google_secret_manager_secret_version.google_oauth_client_id.secret_data
  google_oauth_client_secret = data.google_secret_manager_secret_version.google_oauth_client_secret.secret_data
  # ... (add other credentials)

  # MFA configuration
  enable_mfa      = true
  mfa_enforcement = "optional" # Use "required" for production

  # Authorized domains
  authorized_domains = ["localhost", "staging.adyela.care"]
}
```

### Step 3: Initialize and Plan

```bash
cd infra/environments/staging

# Initialize Terraform
terraform init

# Validate configuration
terraform validate

# Plan deployment
terraform plan -out=identity-platform.tfplan
```

### Step 4: Apply Configuration

```bash
# Apply the plan
terraform apply identity-platform.tfplan

# Note the outputs
terraform output
```

Expected outputs:

```
identity_platform_tenant_id = "projects/adyela-staging/tenants/adyela-tenant-xyz"
identity_platform_service_account = "identity-platform-api-staging@adyela-staging.iam.gserviceaccount.com"
identity_platform_oauth_providers = [
  "google.com",
  "facebook.com",
  "microsoft.com"
]
```

### Step 5: Configure Firebase Console

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project
3. Navigate to "Authentication" > "Sign-in method"
4. Verify OAuth providers are enabled
5. Add authorized domains if needed

## Verification

### Test Authentication Flow

1. **Start local development**:

```bash
cd apps/web
npm run dev
```

2. **Navigate to login page**: http://localhost:5173/login

3. **Test each OAuth provider**:
   - Click "Continue with Google"
   - Click "Continue with Facebook"
   - Click "Continue with Microsoft"

4. **Verify in Firebase Console**:
   - Go to "Authentication" > "Users"
   - Check that users are created with correct provider info

### Test MFA Enrollment

1. Login with email/password
2. Navigate to security settings
3. Enroll in TOTP MFA
4. Scan QR code with authenticator app
5. Verify code
6. Logout and login again
7. Should prompt for MFA code

### Test JWT Custom Claims

Use the service account to verify JWT tokens contain custom claims:

```python
import firebase_admin
from firebase_admin import auth, credentials

# Initialize with service account
cred = credentials.Certificate('path/to/service-account-key.json')
firebase_admin.initialize_app(cred)

# Verify token
id_token = "user-jwt-token"
decoded_token = auth.verify_id_token(id_token)

print(f"User ID: {decoded_token['uid']}")
print(f"Tenant ID: {decoded_token.get('tenant_id')}")
print(f"Role: {decoded_token.get('role')}")
print(f"Permissions: {decoded_token.get('permissions')}")
```

## Monitoring

### View Authentication Logs

```bash
# View all authentication events
gcloud logging read "resource.type=identity_platform" \
  --project=$PROJECT_ID \
  --limit=50 \
  --format=json

# View failed login attempts
gcloud logging read "resource.type=identity_platform AND severity>=ERROR" \
  --project=$PROJECT_ID \
  --limit=20

# View OAuth-specific events
gcloud logging read "resource.type=identity_platform AND jsonPayload.authMethod=~'oauth'" \
  --project=$PROJECT_ID \
  --limit=20
```

### Set Up Alerts

Create alerting policy for suspicious activity:

```bash
# Alert on multiple failed login attempts
gcloud alpha monitoring policies create \
  --notification-channels=CHANNEL_ID \
  --display-name="Failed Login Attempts" \
  --condition-display-name="More than 10 failed logins in 5 minutes" \
  --condition-threshold-value=10 \
  --condition-threshold-duration=300s
```

## Troubleshooting

### Issue: OAuth Provider Not Working

**Symptoms**: OAuth button doesn't work, redirect fails

**Solutions**:

1. Verify OAuth credentials in Secret Manager
2. Check authorized redirect URIs match exactly
3. Ensure domain is in authorized_domains list
4. Check Firebase Console for provider status

### Issue: MFA Not Enrolling

**Symptoms**: MFA enrollment fails, QR code doesn't work

**Solutions**:

1. Verify MFA is enabled in module configuration
2. Check user has verified email
3. Ensure TOTP provider is enabled in Firebase Console
4. Test with different authenticator app

### Issue: JWT Claims Missing

**Symptoms**: Custom claims not in JWT token

**Solutions**:

1. Verify `jwt_custom_claims = true` in module
2. Claims are set during user creation/update
3. User needs to logout and login again to get new token
4. Check service account has proper IAM roles

## Production Deployment

For production, use stricter configuration:

```hcl
module "identity_platform" {
  source = "../../modules/identity"

  # ... basic config ...

  # Stronger password policy
  password_policy = {
    min_length             = 14
    require_uppercase      = true
    require_lowercase      = true
    require_numeric        = true
    require_special_char   = true
    max_failed_attempts    = 3
    lockout_duration       = "30m"
  }

  # Required MFA
  enable_mfa      = true
  mfa_enforcement = "required"

  # Shorter token expiration
  jwt_token_expiration = 1800 # 30 minutes

  # Production domains only
  authorized_domains = ["adyela.care"]
}
```

## Security Checklist

- [ ] OAuth credentials stored in Secret Manager
- [ ] MFA enabled and tested
- [ ] Password policy enforced
- [ ] Audit logging enabled (7-year retention)
- [ ] Service account keys rotated regularly
- [ ] Authorized domains restricted to production only
- [ ] JWT tokens short-lived (<1 hour)
- [ ] All authentication flows tested
- [ ] Monitoring and alerting configured
- [ ] Incident response plan documented

## Rollback Procedure

If issues occur after deployment:

```bash
# 1. Identify last good Terraform state
terraform state list

# 2. Disable problematic provider temporarily
terraform apply -var='enable_google_oauth=false'

# 3. Or rollback completely
terraform destroy -target=module.identity_platform

# 4. Re-apply from known good state
terraform apply -state=backup-state-file
```

## Next Steps

1. **Integrate with API**: Update backend to use service account for token verification
2. **Add Custom Claims**: Implement tenant_id and role assignment in user creation flow
3. **Enable Additional Providers**: Add Apple Sign In if needed
4. **Setup Monitoring Dashboard**: Create custom dashboard for authentication metrics
5. **Test Disaster Recovery**: Practice backup and restore procedures

## References

- [Identity Platform Terraform Module README](../../infra/modules/identity/README.md)
- [OAuth Setup Guide](../guides/OAUTH_SETUP.md)
- [HIPAA Compliance Documentation](../deployment/hipaa-compliance-cost-analysis.md)
- [Google Identity Platform Documentation](https://cloud.google.com/identity-platform/docs)

---

**Version**: 1.0.0
**Last Updated**: 2025-10-11
**Maintained By**: Adyela Infrastructure Team
