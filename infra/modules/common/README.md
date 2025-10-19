# Common Labels and Tags Module

This module provides a standardized labeling and tagging strategy for all GCP
resources in the Adyela infrastructure. It ensures consistent resource
organization, cost attribution, compliance tracking, and operational management.

## Overview

GCP labels are **key-value pairs** attached to resources for:

- 💰 **Cost Attribution** - Track spending by environment, team, service
- 📊 **Organization** - Group and filter resources
- 🔒 **Compliance** - Identify resources containing PHI/PII
- 🤖 **Automation** - Target resources for automated operations
- 📈 **Reporting** - Generate usage and compliance reports

## Features

- ✅ Consistent labeling across all resource types
- ✅ Automatic GCP constraint enforcement (lowercase, 63 char limit)
- ✅ Preset label sets for different resource categories
- ✅ Cost center and billing ID tracking
- ✅ HIPAA and compliance metadata
- ✅ Team and ownership tracking
- ✅ Custom label support

## Usage

### Basic Usage (All Environments)

```hcl
module "labels" {
  source = "../../modules/common"

  environment  = "staging"
  project_name = "adyela"
  team         = "platform"
  owner        = "devops-team"

  cost_center = "engineering"
  billing_id  = "adyela-eng-2024"
}

# Use in other modules
module "cloud_run_api" {
  source = "../../modules/cloud-run-service"

  service_name = "adyela-api-staging"
  labels       = module.labels.compute_labels
}
```

### Application-Specific Labels

```hcl
module "api_labels" {
  source = "../../modules/common"

  environment = "production"
  team        = "backend"
  owner       = "api-team"

  # Application metadata
  application = "api"
  component   = "appointments"
  service     = "adyela-api-production"
  tier        = "backend"
  version     = "v2_1_0"

  # Compliance
  compliance_required = "hipaa"
  data_classification = "restricted"
  hipaa_scope         = "yes"

  # Operations
  backup_policy     = "daily"
  disaster_recovery = "critical"
  high_availability = "true"
  contact_email     = "api-team@adyela.com"

  # Custom labels
  custom_labels = {
    api_version     = "v2"
    release_channel = "stable"
  }
}

# Labels output:
# {
#   managed_by          = "terraform"
#   environment         = "production"
#   project             = "adyela"
#   team                = "backend"
#   application         = "api"
#   component           = "appointments"
#   tier                = "backend"
#   compliance_required = "hipaa"
#   hipaa_scope         = "yes"
#   data_classification = "restricted"
#   backup_policy       = "daily"
#   disaster_recovery   = "critical"
#   ...
# }
```

### Resource-Type-Specific Labels

```hcl
module "labels" {
  source      = "../../modules/common"
  environment = "staging"
  team        = "devops"
}

# Compute resources (Cloud Run, GCE)
resource "google_cloud_run_service" "api" {
  name     = "adyela-api"
  location = "us-central1"

  metadata {
    labels = module.labels.compute_labels
    # Includes: resource_type = "compute"
  }
}

# Storage resources (Cloud Storage, Firestore)
resource "google_storage_bucket" "data" {
  name   = "adyela-data-staging"
  labels = module.labels.storage_labels
  # Includes: resource_type = "storage"
}

# Security resources (Secret Manager)
resource "google_secret_manager_secret" "api_key" {
  secret_id = "api-key-staging"
  labels    = module.labels.security_labels
  # Includes: resource_type = "security"
}

# CI/CD resources (Cloud Build)
resource "google_cloudbuild_trigger" "deploy" {
  name = "deploy-staging"
  tags = module.labels.tags
  # Tags: ["staging", "adyela", "devops", "managed-by-terraform"]
}
```

## Label Categories

### Core Labels (Always Applied)

These labels are **always applied** to every resource:

| Label         | Description          | Example                 |
| ------------- | -------------------- | ----------------------- |
| `managed_by`  | Infrastructure tool  | `terraform`             |
| `terraform`   | Managed by Terraform | `true`                  |
| `environment` | Environment name     | `staging`, `production` |
| `project`     | Project name         | `adyela`                |
| `product`     | Product name         | `adyela-healthcare`     |
| `team`        | Owning team          | `backend`, `platform`   |
| `owner`       | Resource owner       | `api-team`              |
| `cost_center` | Cost center          | `engineering`           |
| `billing_id`  | Billing identifier   | `adyela-eng-2024`       |

### Application Labels (Optional)

Applied when building application resources:

| Label         | Description      | Example                |
| ------------- | ---------------- | ---------------------- |
| `application` | Application name | `api`, `web`, `mobile` |
| `component`   | Component/module | `appointments`, `auth` |
| `service`     | Service name     | `adyela-api-staging`   |
| `tier`        | Service tier     | `backend`, `frontend`  |
| `version`     | App version      | `v1_0_0`               |

### Compliance Labels (Optional)

Critical for HIPAA/GDPR compliance:

| Label                 | Description           | Example                 |
| --------------------- | --------------------- | ----------------------- |
| `compliance_required` | Compliance frameworks | `hipaa`, `gdpr`         |
| `data_classification` | Data sensitivity      | `public`, `restricted`  |
| `hipaa_scope`         | Contains PHI          | `yes`, `no`, `indirect` |

### Operational Labels (Optional)

For operational management:

| Label               | Description      | Example              |
| ------------------- | ---------------- | -------------------- |
| `backup_policy`     | Backup frequency | `daily`, `weekly`    |
| `disaster_recovery` | DR priority      | `critical`, `high`   |
| `high_availability` | HA requirement   | `true`, `false`      |
| `contact_email`     | Owner email      | `team_at_adyela_com` |

## Resource Type Presets

The module provides preset label combinations for different resource categories:

### Compute Labels

For: Cloud Run, GCE, GKE, Cloud Functions

```hcl
labels = module.labels.compute_labels
# Adds: resource_type = "compute"
```

### Storage Labels

For: Cloud Storage, Firestore, Cloud SQL, Memorystore

```hcl
labels = module.labels.storage_labels
# Adds: resource_type = "storage"
```

### Networking Labels

For: VPC, Load Balancers, Cloud CDN, Cloud Armor

```hcl
labels = module.labels.networking_labels
# Adds: resource_type = "networking"
```

### Security Labels

For: Secret Manager, KMS, IAM, Security Command Center

```hcl
labels = module.labels.security_labels
# Adds: resource_type = "security"
```

### CI/CD Labels

For: Cloud Build, Artifact Registry, Deploy Manager

```hcl
labels = module.labels.cicd_labels
# Adds: resource_type = "cicd"
```

### Monitoring Labels

For: Cloud Monitoring, Cloud Logging, Cloud Trace

```hcl
labels = module.labels.monitoring_labels
# Adds: resource_type = "monitoring"
```

## GCP Label Constraints

This module **automatically enforces** GCP's label constraints:

1. **Lowercase only** - All keys and values converted to lowercase
2. **Character set** - Only `a-z`, `0-9`, `_`, `-` allowed (invalid chars
   replaced with `_`)
3. **Length limit** - Values truncated to 63 characters max
4. **Key format** - Keys must start with lowercase letter

**Example:**

```hcl
# Input:
custom_labels = {
  "Team-Email" = "Backend-Team@Adyela.com"
}

# Output (sanitized):
{
  "team_email" = "backend_team_at_adyela_com"
}
```

## Cost Attribution

Labels enable **detailed cost tracking** in GCP Billing:

### By Environment

```sql
SELECT
  labels.value AS environment,
  SUM(cost) AS total_cost
FROM billing_export
WHERE labels.key = 'environment'
GROUP BY environment
```

### By Team

```sql
SELECT
  labels.value AS team,
  SUM(cost) AS total_cost
FROM billing_export
WHERE labels.key = 'team'
GROUP BY team
```

### By Application

```sql
SELECT
  labels.value AS application,
  SUM(cost) AS total_cost
FROM billing_export
WHERE labels.key = 'application'
GROUP BY application
```

## Compliance Queries

Find all resources containing PHI:

```bash
gcloud resource-manager tags bindings list \
  --filter="labels.hipaa_scope=yes"
```

Find all HIPAA-compliant resources:

```bash
gcloud resource-manager tags bindings list \
  --filter="labels.compliance_required=hipaa"
```

Find all restricted data resources:

```bash
gcloud resource-manager tags bindings list \
  --filter="labels.data_classification=restricted"
```

## Inputs

| Name                | Description           | Type           | Default               | Required |
| ------------------- | --------------------- | -------------- | --------------------- | :------: |
| environment         | Environment name      | `string`       | n/a                   |   yes    |
| project_name        | Project name          | `string`       | `"adyela"`            |    no    |
| product_name        | Product name          | `string`       | `"adyela-healthcare"` |    no    |
| team                | Owning team           | `string`       | `"platform"`          |    no    |
| owner               | Resource owner        | `string`       | `"platform-team"`     |    no    |
| cost_center         | Cost center           | `string`       | `"engineering"`       |    no    |
| billing_id          | Billing ID            | `string`       | `"adyela-eng"`        |    no    |
| application         | Application name      | `string`       | `null`                |    no    |
| component           | Component name        | `string`       | `null`                |    no    |
| service             | Service name          | `string`       | `null`                |    no    |
| tier                | Service tier          | `string`       | `null`                |    no    |
| version             | Version               | `string`       | `null`                |    no    |
| compliance_required | Compliance frameworks | `string`       | `"hipaa"`             |    no    |
| data_classification | Data classification   | `string`       | `"confidential"`      |    no    |
| hipaa_scope         | Contains PHI          | `string`       | `"yes"`               |    no    |
| backup_policy       | Backup policy         | `string`       | `null`                |    no    |
| disaster_recovery   | DR tier               | `string`       | `null`                |    no    |
| high_availability   | HA requirement        | `string`       | `null`                |    no    |
| contact_email       | Contact email         | `string`       | `null`                |    no    |
| custom_labels       | Custom labels         | `map(string)`  | `{}`                  |    no    |
| custom_tags         | Custom tags           | `list(string)` | `[]`                  |    no    |

## Outputs

| Name              | Description                             |
| ----------------- | --------------------------------------- |
| labels            | Standard labels (all resources)         |
| tags              | Standard tags (tag-supported resources) |
| compute_labels    | Labels for compute resources            |
| storage_labels    | Labels for storage resources            |
| networking_labels | Labels for networking resources         |
| security_labels   | Labels for security resources           |
| cicd_labels       | Labels for CI/CD resources              |
| monitoring_labels | Labels for monitoring resources         |
| environment       | Environment name                        |
| project_name      | Project name                            |
| team              | Team name                               |

## Best Practices

1. ✅ **Always use this module** - Don't define labels manually
2. ✅ **Use resource-type presets** - `compute_labels`, `storage_labels`, etc.
3. ✅ **Set compliance labels** - Required for HIPAA audit trails
4. ✅ **Include contact information** - Set `contact_email` for critical
   resources
5. ✅ **Use consistent team names** - Standardize on: platform, backend,
   frontend, data, devops, security
6. ✅ **Set disaster recovery tier** - For all production resources
7. ✅ **Document custom labels** - If adding `custom_labels`, document their
   purpose

## Examples

See `examples/labeling/` for complete examples:

- `examples/labeling/production-api/` - Production API service labels
- `examples/labeling/staging-web/` - Staging web service labels
- `examples/labeling/shared-storage/` - Shared storage bucket labels

## Requirements

- Terraform >= 1.0

## Migration Guide

If you have existing resources with manual labels:

1. **Import existing resources** into Terraform state
2. **Add this module** to your configuration
3. **Update resource labels** to use `module.labels.*`
4. **Run terraform plan** to see label changes
5. **Apply changes** (non-destructive - labels can be updated in-place)

**Example:**

```hcl
# Before
resource "google_cloud_run_service" "api" {
  metadata {
    labels = {
      env  = "staging"
      team = "backend"
    }
  }
}

# After
module "labels" {
  source      = "../../modules/common"
  environment = "staging"
  team        = "backend"
  application = "api"
}

resource "google_cloud_run_service" "api" {
  metadata {
    labels = module.labels.compute_labels
  }
}
```
