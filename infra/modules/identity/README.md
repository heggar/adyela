# Identity Platform Terraform Module

This Terraform module configures Google Identity Platform for the Adyela
healthcare platform with support for OAuth providers, Multi-Factor
Authentication (MFA), JWT tokens with custom claims, and HIPAA-compliant audit
logging.

## Features

- ✅ **Multi-Provider Authentication**: Email/password, Google OAuth, Facebook,
  Microsoft
- ✅ **Multi-Factor Authentication (MFA)**: TOTP and SMS verification
- ✅ **JWT Custom Claims**: tenant_id, role, permissions for multi-tenancy
- ✅ **Password Policies**: Configurable complexity requirements
- ✅ **HIPAA Compliance**: Comprehensive audit logging with 7-year retention
- ✅ **Service Account**: Dedicated service account for API authentication
- ✅ **Multi-Tenancy Support**: Tenant isolation for healthcare organizations

## Usage

### Basic Configuration

```hcl
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

  # OAuth credentials (from Secret Manager)
  google_oauth_client_id     = data.google_secret_manager_secret_version.google_oauth_client_id.secret_data
  google_oauth_client_secret = data.google_secret_manager_secret_version.google_oauth_client_secret.secret_data
  facebook_app_id            = data.google_secret_manager_secret_version.facebook_app_id.secret_data
  facebook_app_secret        = data.google_secret_manager_secret_version.facebook_app_secret.secret_data
  microsoft_client_id        = data.google_secret_manager_secret_version.microsoft_client_id.secret_data
  microsoft_client_secret    = data.google_secret_manager_secret_version.microsoft_client_secret.secret_data

  # Enable MFA
  enable_mfa         = true
  mfa_enforcement    = "optional"
  enable_totp_mfa    = true
  enable_sms_mfa     = true

  # Authorized domains
  authorized_domains = [
    "localhost",
    "staging.adyela.care",
    "adyela.care"
  ]

  # Labels
  labels = {
    application = "adyela"
    component   = "identity"
  }
}
```

### Advanced Configuration with Custom Password Policy

```hcl
module "identity_platform" {
  source = "../../modules/identity"

  project_id  = var.project_id
  environment = "production"
  region      = "us-central1"

  # Custom password policy for production
  password_policy = {
    min_length             = 14
    require_uppercase      = true
    require_lowercase      = true
    require_numeric        = true
    require_special_char   = true
    max_failed_attempts    = 3
    lockout_duration       = "30m"
  }

  # Required MFA for production
  enable_mfa      = true
  mfa_enforcement = "required"

  # JWT token configuration
  jwt_token_expiration         = 3600    # 1 hour
  jwt_refresh_token_expiration = 2592000 # 30 days
  jwt_custom_claims            = true

  # HIPAA compliance
  enable_audit_logging = true
  log_retention_days   = 2555 # 7 years

  # Multi-tenancy
  enable_multi_tenancy = true
}
```

## Requirements

| Name        | Version |
| ----------- | ------- |
| terraform   | >= 1.0  |
| google      | ~> 5.0  |
| google-beta | ~> 5.0  |

## Providers

| Name        | Version |
| ----------- | ------- |
| google      | ~> 5.0  |
| google-beta | ~> 5.0  |

## Resources Created

- `google_project_service.identity_toolkit` - Enables Identity Toolkit API
- `google_project_service.identity_platform` - Enables Identity Platform API
- `google_identity_platform_config` - Main Identity Platform configuration
- `google_identity_platform_tenant` - Multi-tenancy tenant (optional)
- `google_identity_platform_default_supported_idp_config` - OAuth providers
  (Google, Facebook, Microsoft)
- `google_service_account.identity_platform_api` - Service account for API
  authentication
- `google_service_account_key.identity_platform_api` - Service account key
- `google_project_iam_member` - IAM roles for service account
- `google_project_iam_audit_config` - Audit logging configuration

## Inputs

### Required Variables

| Name        | Description                                 | Type     | Required |
| ----------- | ------------------------------------------- | -------- | -------- |
| project_id  | GCP Project ID                              | `string` | yes      |
| environment | Environment name (dev, staging, production) | `string` | yes      |

### Authentication Provider Variables

| Name                       | Description                            | Type     | Default |
| -------------------------- | -------------------------------------- | -------- | ------- |
| enable_email_password      | Enable email/password authentication   | `bool`   | `true`  |
| enable_google_oauth        | Enable Google OAuth                    | `bool`   | `true`  |
| google_oauth_client_id     | Google OAuth Client ID                 | `string` | `""`    |
| google_oauth_client_secret | Google OAuth Client Secret (sensitive) | `string` | `""`    |
| enable_facebook            | Enable Facebook authentication         | `bool`   | `true`  |
| facebook_app_id            | Facebook App ID                        | `string` | `""`    |
| facebook_app_secret        | Facebook App Secret (sensitive)        | `string` | `""`    |
| enable_microsoft           | Enable Microsoft authentication        | `bool`   | `true`  |
| microsoft_client_id        | Microsoft Client ID                    | `string` | `""`    |
| microsoft_client_secret    | Microsoft Client Secret (sensitive)    | `string` | `""`    |

### Password Policy Variables

| Name            | Description                   | Type     | Default          |
| --------------- | ----------------------------- | -------- | ---------------- |
| password_policy | Password policy configuration | `object` | See variables.tf |

Default password policy:

- Minimum length: 12 characters
- Requires uppercase, lowercase, numeric, and special characters
- Max failed attempts: 5
- Lockout duration: 15 minutes

### MFA Variables

| Name            | Description                        | Type     | Default      |
| --------------- | ---------------------------------- | -------- | ------------ |
| enable_mfa      | Enable Multi-Factor Authentication | `bool`   | `true`       |
| mfa_enforcement | MFA enforcement level              | `string` | `"optional"` |
| enable_totp_mfa | Enable TOTP MFA                    | `bool`   | `true`       |
| enable_sms_mfa  | Enable SMS MFA                     | `bool`   | `true`       |

### JWT Token Variables

| Name                         | Description                            | Type     | Default   |
| ---------------------------- | -------------------------------------- | -------- | --------- |
| jwt_token_expiration         | JWT token expiration (seconds)         | `number` | `3600`    |
| jwt_refresh_token_expiration | JWT refresh token expiration (seconds) | `number` | `2592000` |
| jwt_custom_claims            | Enable custom JWT claims               | `bool`   | `true`    |

### HIPAA Compliance Variables

| Name                 | Description              | Type     | Default |
| -------------------- | ------------------------ | -------- | ------- |
| enable_audit_logging | Enable audit logging     | `bool`   | `true`  |
| log_retention_days   | Audit log retention days | `number` | `2555`  |

## Outputs

| Name                          | Description                             |
| ----------------------------- | --------------------------------------- |
| identity_platform_config_name | Identity Platform configuration name    |
| tenant_id                     | Tenant ID (if multi-tenancy enabled)    |
| service_account_email         | Service account email                   |
| authorized_domains            | Authorized domains list                 |
| mfa_enabled                   | Whether MFA is enabled                  |
| oauth_providers_configured    | List of configured OAuth providers      |
| authentication_providers      | Map of enabled authentication providers |

## Security Considerations

### HIPAA Compliance

1. **Audit Logging**: All authentication events are logged for 7 years (2555
   days)
2. **MFA**: Multi-factor authentication is strongly recommended for production
3. **Password Policy**: Strong password requirements by default
4. **Encryption**: All tokens and credentials are encrypted at rest and in
   transit
5. **Access Control**: Least-privilege IAM roles for service accounts

### Best Practices

1. **Secret Management**: Store OAuth credentials in GCP Secret Manager
2. **MFA Enforcement**: Use `mfa_enforcement = "required"` for production
3. **Token Expiration**: Keep JWT tokens short-lived (1 hour recommended)
4. **Authorized Domains**: Only list trusted domains
5. **Service Account Keys**: Rotate keys regularly

### OAuth Provider Setup

#### Google OAuth

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create OAuth 2.0 Client ID
3. Add authorized redirect URIs:
   - `http://localhost:9099/__/auth/handler` (development)
   - `https://staging.adyela.care/__/auth/handler` (staging)
   - `https://adyela.care/__/auth/handler` (production)

#### Facebook OAuth

1. Go to [Facebook Developers](https://developers.facebook.com/)
2. Create a new app with Facebook Login
3. Add OAuth redirect URIs (same as above)

#### Microsoft OAuth

1. Go to [Azure Portal](https://portal.azure.com/)
2. Register a new application
3. Add redirect URIs (same as above)
4. Add API permission: `User.Read`

## Testing

### Validate Configuration

```bash
terraform init
terraform validate
terraform plan
```

### Test Authentication Flow

See `docs/guides/OAUTH_SETUP.md` for complete testing instructions.

## Migration Notes

If upgrading from Firebase Auth to Identity Platform:

1. Identity Platform is backward compatible with Firebase Auth
2. Existing users and authentication will continue to work
3. MFA must be explicitly enabled for existing users
4. Custom claims can be added to existing JWT tokens

## Troubleshooting

### Common Issues

1. **"API not enabled" error**: Run `terraform apply` again after APIs are
   enabled
2. **OAuth redirect mismatch**: Verify authorized redirect URIs match exactly
3. **MFA not working**: Ensure phone numbers are verified for SMS MFA

### Useful Commands

```bash
# View Identity Platform configuration
gcloud identity idp describe

# List OAuth providers
gcloud identity providers list

# Test service account authentication
gcloud auth activate-service-account --key-file=sa-key.json
```

## Related Documentation

- [Google Identity Platform Documentation](https://cloud.google.com/identity-platform/docs)
- [Firebase Authentication Documentation](https://firebase.google.com/docs/auth)
- [HIPAA Compliance Guide](../../docs/deployment/hipaa-compliance-cost-analysis.md)
- [OAuth Setup Guide](../../docs/guides/OAUTH_SETUP.md)

## Support

For issues or questions, please refer to:

- Project documentation in `docs/`
- Create an issue in the project repository
- Contact the infrastructure team

## License

UNLICENSED - Private healthcare application

---

**Version**: 1.0.0 **Last Updated**: 2025-10-11 **Maintained By**: Adyela
Infrastructure Team
