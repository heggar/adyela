# Cloud Storage Bucket Terraform Module

This module creates and manages Google Cloud Storage buckets for file storage,
backups, static website hosting, and data lakes.

## Features

- ✅ Multiple storage classes (STANDARD, NEARLINE, COLDLINE, ARCHIVE)
- ✅ Lifecycle rules for cost optimization
- ✅ Object versioning for data protection
- ✅ CORS configuration for web access
- ✅ Customer-managed encryption keys (CMEK)
- ✅ Static website hosting
- ✅ Access logging
- ✅ Retention policies for compliance
- ✅ Autoclass for automatic cost optimization
- ✅ IAM bindings with least-privilege access
- ✅ Pub/Sub notifications for events

## Usage

### Basic Bucket for File Storage

```hcl
module "file_storage" {
  source = "../../modules/cloud-storage"

  project_id  = "my-project"
  bucket_name = "adyela-files-staging"
  location    = "us-central1"
  environment = "staging"

  # Standard storage for frequently accessed files
  storage_class = "STANDARD"

  # Security best practices
  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"

  # IAM
  reader_members = [
    "serviceAccount:api@my-project.iam.gserviceaccount.com"
  ]

  writer_members = [
    "serviceAccount:uploader@my-project.iam.gserviceaccount.com"
  ]

  labels = module.labels.storage_labels
}
```

### Bucket with Lifecycle Rules (Cost Optimization)

```hcl
module "backup_storage" {
  source = "../../modules/cloud-storage"

  project_id  = "my-project"
  bucket_name = "adyela-backups-staging"
  location    = "us"
  environment = "staging"

  # Enable versioning for backups
  versioning_enabled = true

  # Lifecycle rules to save costs
  lifecycle_rules = [
    # Delete old versions after 30 days
    {
      action = {
        type = "Delete"
      }
      condition = {
        with_state         = "ARCHIVED"
        num_newer_versions = 3
      }
    },
    # Transition to NEARLINE after 30 days
    {
      action = {
        type          = "SetStorageClass"
        storage_class = "NEARLINE"
      }
      condition = {
        age = 30
      }
    },
    # Transition to COLDLINE after 90 days
    {
      action = {
        type          = "SetStorageClass"
        storage_class = "COLDLINE"
      }
      condition = {
        age = 90
      }
    },
    # Transition to ARCHIVE after 365 days
    {
      action = {
        type          = "SetStorageClass"
        storage_class = "ARCHIVE"
      }
      condition = {
        age = 365
      }
    },
    # Delete backups older than 7 years
    {
      action = {
        type = "Delete"
      }
      condition = {
        age = 2555  # 7 years
      }
    }
  ]

  labels = module.labels.storage_labels
}
```

### Static Website Hosting

```hcl
module "static_website" {
  source = "../../modules/cloud-storage"

  project_id  = "my-project"
  bucket_name = "www.adyela.com"  # Must match domain
  location    = "us"
  environment = "production"

  # Website configuration
  website_config = {
    main_page_suffix = "index.html"
    not_found_page   = "404.html"
  }

  # CORS for web access
  cors_config = {
    origin = ["https://adyela.com"]
    method = ["GET", "HEAD", "OPTIONS"]
    response_header = ["Content-Type"]
    max_age_seconds = 3600
  }

  # Make bucket public for website
  make_public = true

  # Lifecycle: Delete old versions after 7 days
  lifecycle_rules = [
    {
      action = {
        type = "Delete"
      }
      condition = {
        age        = 7
        with_state = "ARCHIVED"
      }
    }
  ]

  labels = module.labels.storage_labels
}
```

### Encrypted Bucket with CMEK

```hcl
module "secure_storage" {
  source = "../../modules/cloud-storage"

  project_id  = "my-project"
  bucket_name = "adyela-phi-data-production"
  location    = "us-central1"
  environment = "production"

  # Customer-managed encryption
  encryption_key = "projects/my-project/locations/us-central1/keyRings/phi-keyring/cryptoKeys/phi-key"

  # Compliance: 7-year retention for PHI
  retention_policy = {
    retention_period = 220752000  # 7 years in seconds
    is_locked        = true
  }

  # Access logging for audit
  logging_config = {
    log_bucket        = "adyela-audit-logs"
    log_object_prefix = "phi-access/"
  }

  # Strict IAM
  admin_members = [
    "serviceAccount:phi-admin@my-project.iam.gserviceaccount.com"
  ]

  # Prevent public access
  public_access_prevention = "enforced"

  labels = merge(
    module.labels.storage_labels,
    {
      data_classification = "phi"
      compliance          = "hipaa"
    }
  )
}
```

### Bucket with Pub/Sub Notifications

```hcl
module "upload_bucket" {
  source = "../../modules/cloud-storage"

  project_id  = "my-project"
  bucket_name = "adyela-uploads-staging"
  location    = "us-central1"
  environment = "staging"

  # Trigger Cloud Function on file upload
  notification_config = {
    topic          = "projects/my-project/topics/file-uploads"
    payload_format = "JSON_API_V1"

    event_types = [
      "OBJECT_FINALIZE",
      "OBJECT_DELETE"
    ]

    # Only notify for specific prefixes
    object_name_prefix = "patient-documents/"

    custom_attributes = {
      environment = "staging"
      app         = "adyela"
    }
  }

  labels = module.labels.storage_labels
}
```

### Autoclass for Automatic Cost Optimization

```hcl
module "data_lake" {
  source = "../../modules/cloud-storage"

  project_id  = "my-project"
  bucket_name = "adyela-datalake-production"
  location    = "us"
  environment = "production"

  # Autoclass automatically moves objects to cheaper storage classes
  enable_autoclass                = true
  autoclass_terminal_storage_class = "ARCHIVE"

  # No manual lifecycle rules needed with autoclass
  lifecycle_rules = []

  labels = module.labels.storage_labels
}
```

## Lifecycle Rule Examples

### Delete objects after N days

```hcl
{
  action = {
    type = "Delete"
  }
  condition = {
    age = 30  # Days
  }
}
```

### Transition to cheaper storage class

```hcl
{
  action = {
    type          = "SetStorageClass"
    storage_class = "NEARLINE"
  }
  condition = {
    age = 90
  }
}
```

### Delete specific file types

```hcl
{
  action = {
    type = "Delete"
  }
  condition = {
    age             = 7
    matches_suffix  = [".tmp", ".log"]
  }
}
```

### Keep only recent versions

```hcl
{
  action = {
    type = "Delete"
  }
  condition = {
    num_newer_versions = 5
    with_state         = "ARCHIVED"
  }
}
```

## Inputs

| Name               | Description                   | Type           | Default         | Required |
| ------------------ | ----------------------------- | -------------- | --------------- | :------: |
| project_id         | GCP project ID                | `string`       | n/a             |   yes    |
| bucket_name        | Bucket name (globally unique) | `string`       | n/a             |   yes    |
| location           | Bucket location               | `string`       | `"us-central1"` |    no    |
| environment        | Environment                   | `string`       | n/a             |   yes    |
| storage_class      | Storage class                 | `string`       | `"STANDARD"`    |    no    |
| versioning_enabled | Enable versioning             | `bool`         | `false`         |    no    |
| lifecycle_rules    | Lifecycle rules               | `list(object)` | `[]`            |    no    |
| cors_config        | CORS configuration            | `object`       | `null`          |    no    |
| encryption_key     | CMEK key name                 | `string`       | `null`          |    no    |
| website_config     | Website configuration         | `object`       | `null`          |    no    |
| retention_policy   | Retention policy              | `object`       | `null`          |    no    |
| enable_autoclass   | Enable autoclass              | `bool`         | `false`         |    no    |
| make_public        | Make bucket public            | `bool`         | `false`         |    no    |
| reader_members     | IAM readers                   | `list(string)` | `[]`            |    no    |
| writer_members     | IAM writers                   | `list(string)` | `[]`            |    no    |
| admin_members      | IAM admins                    | `list(string)` | `[]`            |    no    |

## Outputs

| Name            | Description              |
| --------------- | ------------------------ |
| bucket_name     | Name of the bucket       |
| bucket_url      | URL of the bucket        |
| bucket_location | Location of the bucket   |
| public_url      | Public URL for objects   |
| website_url     | Website URL (if enabled) |

## Storage Classes and Pricing

| Class    | Use Case                      | Min Duration | Retrieval Cost | Monthly Cost (per GB) |
| -------- | ----------------------------- | ------------ | -------------- | --------------------- |
| STANDARD | Hot data, frequent access     | None         | None           | $0.020                |
| NEARLINE | Infrequent access (< 1/month) | 30 days      | $0.01/GB       | $0.010                |
| COLDLINE | Rare access (< 1/quarter)     | 90 days      | $0.02/GB       | $0.004                |
| ARCHIVE  | Long-term archival            | 365 days     | $0.05/GB       | $0.0012               |

**Cost Optimization Example:**

- 100GB stored for 1 year
- STANDARD: $24/year
- NEARLINE: $12/year (50% savings)
- COLDLINE: $4.80/year (80% savings)
- ARCHIVE: $1.44/year (94% savings)

## Security Best Practices

1. ✅ **Use uniform bucket-level access** - Simplifies IAM management
2. ✅ **Enforce public access prevention** - Prevents accidental exposure
3. ✅ **Enable versioning for important data** - Protects against accidental
   deletion
4. ✅ **Use CMEK for sensitive data** - Customer-managed encryption keys
5. ✅ **Configure access logging** - Audit trail for compliance
6. ✅ **Set retention policies for compliance** - Prevent early deletion
7. ✅ **Use least-privilege IAM** - Grant minimum required permissions

## HIPAA Compliance

For PHI storage:

```hcl
module "phi_storage" {
  source = "../../modules/cloud-storage"

  bucket_name = "phi-storage-production"
  environment = "production"

  # Encryption
  encryption_key = var.cmek_key

  # Audit logging
  logging_config = {
    log_bucket = "audit-logs"
  }

  # 7-year retention
  retention_policy = {
    retention_period = 220752000
    is_locked        = true
  }

  # Strict access
  public_access_prevention = "enforced"

  # Labels for compliance
  labels = {
    hipaa_scope         = "yes"
    data_classification = "phi"
    compliance          = "hipaa"
  }
}
```

## Examples

See `examples/` directory for complete usage examples:

- `examples/file-storage/` - Basic file storage
- `examples/backup-storage/` - Backup with lifecycle rules
- `examples/static-website/` - Static website hosting
- `examples/phi-storage/` - HIPAA-compliant PHI storage

## Requirements

- Terraform >= 1.0
- Google Cloud Provider >= 6.0
- Cloud Storage API enabled in GCP project

## Troubleshooting

### "Bucket name already exists"

Bucket names are globally unique across all GCP projects. Use a more specific
name like `my-company-app-environment-bucket`.

### "Permission denied" when creating bucket

Ensure the service account has `roles/storage.admin` or
`roles/storage.bucketAdmin` role.

### Lifecycle rules not working

Lifecycle rules run once per day. Wait 24-48 hours for rules to take effect.

### CMEK encryption fails

Ensure the Cloud Storage service account has
`roles/cloudkms.cryptoKeyEncrypterDecrypter` on the KMS key.
