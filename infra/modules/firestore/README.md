# Firestore Database Terraform Module

This module creates and manages Google Firestore databases with security rules,
indexes, and automated backups for NoSQL data storage.

## Features

- ✅ Firestore Native or Datastore mode
- ✅ Point-in-Time Recovery (PITR) with 7-day retention
- ✅ Automated daily backups with configurable retention
- ✅ Security rules deployment from local files
- ✅ Composite index management
- ✅ Multi-region support for high availability
- ✅ Delete protection for production databases
- ✅ IAM bindings with least-privilege access
- ✅ Export bucket creation for data migration
- ✅ HIPAA-compliant configuration

## Usage

### Basic Firestore Database

```hcl
module "firestore" {
  source = "../../modules/firestore"

  project_id    = "my-project"
  database_name = "(default)"  # Default database
  location      = "nam5"       # North America multi-region

  # Enable PITR for data protection
  enable_pitr = true

  # Enable automated backups
  enable_backups          = true
  backup_retention_days   = 30

  # Delete protection
  delete_protection = true

  # IAM: Grant access to Cloud Run services
  firestore_users = [
    "serviceAccount:api@my-project.iam.gserviceaccount.com",
    "serviceAccount:admin@my-project.iam.gserviceaccount.com"
  ]
}
```

### With Security Rules

```hcl
module "firestore_with_rules" {
  source = "../../modules/firestore"

  project_id    = "my-project"
  database_name = "(default)"
  location      = "nam5"

  # Deploy security rules from file
  security_rules_file = "${path.module}/firestore.rules"

  # Enable PITR and backups
  enable_pitr            = true
  enable_backups         = true
  backup_retention_days  = 30

  firestore_users = [
    "serviceAccount:api@my-project.iam.gserviceaccount.com"
  ]
}
```

### With Composite Indexes

```hcl
module "firestore_with_indexes" {
  source = "../../modules/firestore"

  project_id = "my-project"
  location   = "nam5"

  # Composite indexes for complex queries
  indexes = [
    # Index for querying appointments by tenant and date
    {
      name       = "appointments-tenant-date"
      collection = "appointments"
      fields = [
        { field_path = "tenant_id", order = "ASC" },
        { field_path = "appointment_date", order = "ASC" },
        { field_path = "status", order = "ASC" }
      ]
    },

    # Index for querying patients by tenant and created date
    {
      name       = "patients-tenant-created"
      collection = "patients"
      fields = [
        { field_path = "tenant_id", order = "ASC" },
        { field_path = "created_at", order = "DESC" }
      ]
    },

    # Array-contains index for tags
    {
      name       = "medical-records-tags"
      collection = "medical_records"
      query_scope = "COLLECTION"
      fields = [
        { field_path = "tenant_id", order = "ASC" },
        { field_path = "tags", array_config = "CONTAINS" }
      ]
    },

    # Collection group query index
    {
      name        = "appointments-global"
      collection  = "appointments"
      query_scope = "COLLECTION_GROUP"
      fields = [
        { field_path = "practitioner_id", order = "ASC" },
        { field_path = "appointment_date", order = "ASC" }
      ]
    }
  ]

  enable_pitr   = true
  enable_backups = true
}
```

### Production Configuration (HIPAA Compliant)

```hcl
module "firestore_production" {
  source = "../../modules/firestore"

  project_id    = "adyela-production"
  database_name = "(default)"
  location      = "nam5"  # Multi-region for HA

  # Firestore Native mode (not Datastore)
  database_type = "FIRESTORE_NATIVE"

  # Optimistic concurrency for better performance
  concurrency_mode = "OPTIMISTIC"

  # Point-in-Time Recovery (7-day retention)
  enable_pitr = true

  # Daily backups with 90-day retention (HIPAA requirement)
  enable_backups        = true
  backup_retention_days = 90

  # Prevent accidental deletion
  delete_protection = true
  force_destroy     = false

  # Deploy security rules
  security_rules_file = "${path.module}/firestore.rules"

  # Composite indexes
  indexes = [
    # Tenant-scoped appointment queries
    {
      name       = "appointments-tenant-date-status"
      collection = "appointments"
      fields = [
        { field_path = "tenant_id", order = "ASC" },
        { field_path = "appointment_date", order = "ASC" },
        { field_path = "status", order = "ASC" }
      ]
    }
  ]

  # IAM: Least-privilege access
  firestore_users = [
    "serviceAccount:api@adyela-production.iam.gserviceaccount.com",
    "serviceAccount:api-admin@adyela-production.iam.gserviceaccount.com"
  ]

  # Create export bucket for data migration
  create_export_bucket = true

  # Labels for compliance
  labels = merge(
    module.labels.storage_labels,
    {
      hipaa_scope         = "yes"
      data_classification = "phi"
      compliance          = "hipaa"
    }
  )
}
```

## Security Rules Example

See `examples/firestore.rules` for a complete multi-tenant HIPAA-compliant
security rules example.

**Key security patterns:**

```javascript
// Check if user belongs to tenant
function belongsToTenant(tenantId) {
  return request.auth.token.tenant_id == tenantId;
}

// Tenant-scoped appointments
match /tenants/{tenantId}/appointments/{appointmentId} {
  allow read: if belongsToTenant(tenantId);
  allow create: if belongsToTenant(tenantId) && validateTenantId();
}

// Medical records (immutable - HIPAA requirement)
match /tenants/{tenantId}/medical_records/{recordId} {
  allow read: if belongsToTenant(tenantId) && (
    isOwner(resource.data.patient_id) ||
    isPractitioner()
  );

  allow create: if belongsToTenant(tenantId) && isPractitioner();

  // Medical records cannot be deleted
  allow delete: if false;
}
```

## Index Management

Firestore automatically creates single-field indexes. You only need to define
**composite indexes** for queries with multiple filters/sorts.

### When to Create Indexes

Create composite indexes when you query with:

- Multiple equality filters:
  `where('tenant_id', '==', X).where('status', '==', Y)`
- Equality + range filter: `where('tenant_id', '==', X).where('date', '>=', Y)`
- Multiple orderBy:
  `where('tenant_id', '==', X).orderBy('date').orderBy('priority')`

### Index Configuration

```hcl
indexes = [
  {
    name       = "index-name"
    collection = "collection-name"
    query_scope = "COLLECTION"  # or "COLLECTION_GROUP"
    fields = [
      { field_path = "field1", order = "ASC" },
      { field_path = "field2", order = "DESC" },
      { field_path = "array_field", array_config = "CONTAINS" }
    ]
  }
]
```

## Backup and Recovery

### Point-in-Time Recovery (PITR)

- **Retention**: 7 days
- **Granularity**: 1 minute
- **Cost**: $0.18/GB/month (in addition to storage)

```hcl
enable_pitr = true
```

**Restore from PITR:**

```bash
gcloud firestore databases restore \
  --source-database='(default)' \
  --destination-database='restored-db' \
  --source-backup=YYYY-MM-DDTHH:MM:SS
```

### Automated Backups

- **Schedule**: Daily (configurable)
- **Retention**: 7-90 days (configurable)
- **Cost**: $0.026/GB/month

```hcl
enable_backups        = true
backup_retention_days = 30
```

**Restore from backup:**

```bash
gcloud firestore databases restore \
  --source-backup=projects/PROJECT/locations/LOCATION/backups/BACKUP_ID \
  --destination-database='restored-db'
```

### Manual Export/Import

Use the export bucket:

```bash
# Export
gcloud firestore export gs://PROJECT-firestore-exports/export-$(date +%Y%m%d)

# Import
gcloud firestore import gs://PROJECT-firestore-exports/export-20250119
```

## Inputs

| Name                  | Description                        | Type           | Default              | Required |
| --------------------- | ---------------------------------- | -------------- | -------------------- | :------: |
| project_id            | GCP project ID                     | `string`       | n/a                  |   yes    |
| database_name         | Database name                      | `string`       | `"(default)"`        |    no    |
| location              | Database location                  | `string`       | `"nam5"`             |    no    |
| database_type         | FIRESTORE_NATIVE or DATASTORE_MODE | `string`       | `"FIRESTORE_NATIVE"` |    no    |
| enable_pitr           | Enable Point-in-Time Recovery      | `bool`         | `true`               |    no    |
| enable_backups        | Enable automated backups           | `bool`         | `true`               |    no    |
| backup_retention_days | Backup retention (days)            | `number`       | `7`                  |    no    |
| delete_protection     | Prevent accidental deletion        | `bool`         | `true`               |    no    |
| security_rules_file   | Path to firestore.rules            | `string`       | `null`               |    no    |
| indexes               | Composite indexes                  | `list(object)` | `[]`                 |    no    |
| create_export_bucket  | Create export bucket               | `bool`         | `true`               |    no    |
| firestore_users       | IAM users (read/write)             | `list(string)` | `[]`                 |    no    |

## Outputs

| Name               | Description        |
| ------------------ | ------------------ |
| database_name      | Database name      |
| database_location  | Database location  |
| pitr_enabled       | PITR status        |
| backup_enabled     | Backup status      |
| export_bucket_name | Export bucket name |
| indexes_created    | Number of indexes  |

## Locations

### Single-Region (Lower Latency)

- `us-central1`, `us-east1`, `us-west1`
- `europe-west1`, `europe-west2`
- `asia-southeast1`

### Multi-Region (High Availability)

- `nam5` (North America)
- `eur3` (Europe)
- `nam-eur6` (North America + Europe)

**Recommendation:** Use multi-region (`nam5`, `eur3`) for production HA.

## Cost Estimation

### Storage Costs

- **Document storage**: $0.18/GB/month
- **PITR**: +$0.18/GB/month
- **Backups**: $0.026/GB/month

### Operation Costs

- **Document reads**: $0.06 per 100,000
- **Document writes**: $0.18 per 100,000
- **Document deletes**: $0.02 per 100,000

**Example (100GB, 1M reads/day, 100K writes/day):**

- Storage: $18/month
- PITR: +$18/month
- Backups: +$2.60/month
- Operations: ~$60/month
- **Total: ~$100/month**

## Security Best Practices

1. ✅ **Use security rules** - Always deploy firestore.rules
2. ✅ **Enable PITR** - 7-day recovery window
3. ✅ **Enable daily backups** - 30-90 day retention for production
4. ✅ **Delete protection** - Prevent accidental deletion
5. ✅ **Least-privilege IAM** - Grant minimum required permissions
6. ✅ **Audit logging** - Enable Cloud Audit Logs
7. ✅ **Tenant isolation** - Use tenant-scoped collections

## HIPAA Compliance

For PHI storage in Firestore:

```hcl
module "hipaa_firestore" {
  source = "../../modules/firestore"

  # Enable all protections
  enable_pitr       = true
  delete_protection = true
  enable_backups    = true
  backup_retention_days = 90  # 7 years for medical records

  # Deploy security rules
  security_rules_file = "firestore.rules"

  # Labels
  labels = {
    hipaa_scope         = "yes"
    data_classification = "phi"
    compliance          = "hipaa"
  }
}
```

**HIPAA Requirements:**

- ✅ Encryption at rest (automatic)
- ✅ Encryption in transit (automatic)
- ✅ Audit logging (enable Cloud Audit Logs)
- ✅ Access controls (security rules + IAM)
- ✅ Data backup (automated daily backups)
- ✅ Data retention (7 years for medical records)
- ✅ Immutability (security rules prevent deletion of medical records)

## Troubleshooting

### "Default database already exists"

Firestore allows only one `(default)` database per project. Use a named
database:

```hcl
database_name = "my-database"
```

### "Index already exists"

Firestore may have auto-created the index. Import it:

```bash
terraform import 'module.firestore.google_firestore_index.indexes["index-name"]' \
  projects/PROJECT/databases/DATABASE/collectionGroups/COLLECTION/indexes/INDEX_ID
```

### Security rules not applying

Wait 1-2 minutes for rules to propagate. Verify deployment:

```bash
gcloud firebaserules releases list --project=PROJECT
```

### PITR restore fails

Ensure you're restoring to a new database, not overwriting existing:

```bash
gcloud firestore databases restore \
  --destination-database='new-database-name'  # Must be new
```

## Examples

See `examples/firestore.rules` for multi-tenant HIPAA-compliant security rules.

## Requirements

- Terraform >= 1.0
- Google Cloud Provider >= 6.0
- Firestore API enabled
- Firebase Rules API enabled (for security rules)
