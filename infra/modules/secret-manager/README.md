# Secret Manager Module

Secure secrets management with automatic rotation, replication, and granular
access control.

## Features

- ✅ Secret creation and versioning
- ✅ Automatic secret rotation
- ✅ Auto-generated random secrets
- ✅ Replication policies (automatic, multi-region)
- ✅ Customer-Managed Encryption Keys (CMEK)
- ✅ IAM access control per secret
- ✅ Pub/Sub notifications for changes
- ✅ Secret expiration (TTL)
- ✅ Cloud Run integration

## Cost

- First 6 secret versions: **FREE**
- After 6: $0.06 per secret version per month
- Secret access: $0.03 per 10,000 operations
- **Typical**: $2-10/month for 50 secrets

## Basic Usage

```hcl
module "secrets" {
  source = "../../modules/secret-manager"
  project_id = "adyela-staging"

  secrets = [{
    secret_id   = "database-url"
    secret_data = "postgresql://user:pass@host/db"
    iam_bindings = [{
      member = "serviceAccount:api@project.iam.gserviceaccount.com"
      role   = "roles/secretmanager.secretAccessor"
    }]
  }]
}
```

## Auto-Generated Secrets

```hcl
secrets = [{
  secret_id       = "jwt-secret"
  generate_random = true
  random_length   = 64
  rotation_period = "7776000s"  # 90 days
}]
```

## HIPAA Compliance

```hcl
secrets = [{
  secret_id          = "phi-access-token"
  replication_policy = "user_managed"
  replicas           = [{ location = "us-central1", kms_key_name = var.cmek_key }]
  rotation_period    = "7776000s"
  labels             = { hipaa_scope = "yes", phi_related = "true" }
}]
```

## References

- [Secret Manager Docs](https://cloud.google.com/secret-manager/docs)
- [Automatic Rotation](https://cloud.google.com/secret-manager/docs/rotation)
