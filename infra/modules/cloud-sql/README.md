# Cloud SQL PostgreSQL Terraform Module

This module creates and manages Google Cloud SQL PostgreSQL instances with high
availability, automated backups, read replicas, and private networking.

## Features

- ✅ PostgreSQL 14, 15, or 16
- ✅ High availability with automatic failover
- ✅ Automated daily backups with retention
- ✅ Point-in-Time Recovery (PITR)
- ✅ Read replicas for load distribution
- ✅ Private IP networking (VPC)
- ✅ SSL/TLS encryption
- ✅ Query Insights for performance monitoring
- ✅ Automatic storage scaling
- ✅ Secret Manager integration
- ✅ IAM authentication support

## Usage

### Basic PostgreSQL Instance

```hcl
module "postgres" {
  source = "../../modules/cloud-sql"

  project_id    = "my-project"
  instance_name = "analytics-db"
  region        = "us-central1"
  environment   = "staging"

  # PostgreSQL version
  database_version = "POSTGRES_15"

  # Machine type
  tier = "db-custom-2-7680"  # 2 vCPU, 7.5 GB RAM

  # Storage
  disk_type       = "PD_SSD"
  disk_size       = 20  # GB
  disk_autoresize = true

  # Databases to create
  databases = ["analytics", "reporting"]

  # Create admin user
  create_admin_user                = true
  admin_user_name                  = "admin"
  store_password_in_secret_manager = true

  # Backups
  enable_backups = true
  enable_pitr    = true

  # Private IP (requires VPC)
  enable_public_ip = false
  private_network  = "projects/my-project/global/networks/default"

  labels = module.labels.storage_labels
}
```

### High Availability Production Setup

```hcl
module "postgres_ha" {
  source = "../../modules/cloud-sql"

  project_id    = "my-project"
  instance_name = "analytics-db-prod"
  region        = "us-central1"
  environment   = "production"

  database_version = "POSTGRES_15"

  # High-performance tier
  tier = "db-custom-4-15360"  # 4 vCPU, 15 GB RAM

  # Enable HA with automatic failover
  high_availability = true

  # SSD storage with autoresize
  disk_type       = "PD_SSD"
  disk_size       = 100
  disk_autoresize = true

  # Enhanced backups
  enable_backups               = true
  backup_start_time            = "03:00"  # 3 AM UTC
  backup_retention_count       = 30       # Keep 30 backups
  enable_pitr                  = true
  transaction_log_retention_days = 7

  # Deletion protection
  deletion_protection = true

  # Private IP only (no public access)
  enable_public_ip = false
  private_network  = module.vpc.network_self_link
  require_ssl      = true

  # Maintenance window (Sunday 3 AM)
  maintenance_window = {
    day          = 7
    hour         = 3
    update_track = "stable"
  }

  # PostgreSQL configuration
  database_flags = [
    { name = "max_connections", value = "200" },
    { name = "shared_buffers", value = "3932160" },  # 3.75 GB
    { name = "work_mem", value = "32768" },          # 32 MB
    { name = "maintenance_work_mem", value = "1048576" },  # 1 GB
    { name = "effective_cache_size", value = "11796480" }  # 11.25 GB
  ]

  # Query Insights
  enable_query_insights = true

  # Databases
  databases = ["analytics", "reporting", "metrics"]

  # IAM
  sql_client_members = [
    "serviceAccount:analytics@my-project.iam.gserviceaccount.com"
  ]

  labels = module.labels.storage_labels
}
```

### With Read Replicas

```hcl
module "postgres_with_replicas" {
  source = "../../modules/cloud-sql"

  project_id    = "my-project"
  instance_name = "analytics-db"
  region        = "us-central1"
  environment   = "production"

  tier = "db-custom-4-15360"

  # Primary instance configuration
  high_availability = true
  enable_backups    = true
  enable_pitr       = true

  # Read replicas in different regions
  read_replicas = {
    # Read replica in us-east1
    "us-east1" = {
      region = "us-east1"
      tier   = "db-custom-2-7680"  # Smaller tier for replica
    }

    # Read replica in europe-west1
    "europe-west1" = {
      region = "us-central1"  # Same region for failover
      tier   = "db-custom-4-15360"  # Same tier
      failover_target = true  # Can become master
    }
  }

  databases = ["analytics"]

  private_network = module.vpc.network_self_link
  enable_public_ip = false

  labels = module.labels.storage_labels
}
```

### Public IP with Authorized Networks

```hcl
module "postgres_public" {
  source = "../../modules/cloud-sql"

  project_id    = "my-project"
  instance_name = "dev-db"
  region        = "us-central1"
  environment   = "development"

  tier = "db-f1-micro"  # Smallest tier for dev

  # Enable public IP
  enable_public_ip = true

  # Restrict access to specific IPs
  authorized_networks = [
    {
      name = "office-network"
      cidr = "203.0.113.0/24"
    },
    {
      name = "vpn-gateway"
      cidr = "198.51.100.50/32"
    }
  ]

  # Require SSL
  require_ssl = true

  databases = ["dev_db"]

  labels = module.labels.storage_labels
}
```

### With Custom Users

```hcl
module "postgres_users" {
  source = "../../modules/cloud-sql"

  project_id    = "my-project"
  instance_name = "app-db"
  region        = "us-central1"
  environment   = "production"

  # Create admin user
  create_admin_user = true

  # Additional application users
  additional_users = {
    "app_readonly" = {
      password = random_password.readonly_user.result
    }
    "app_readwrite" = {
      password = random_password.readwrite_user.result
    }
    "backup_user" = {
      password = random_password.backup_user.result
    }
  }

  databases = ["application"]

  labels = module.labels.storage_labels
}

# Generate passwords for users
resource "random_password" "readonly_user" {
  length  = 32
  special = true
}

resource "random_password" "readwrite_user" {
  length  = 32
  special = true
}

resource "random_password" "backup_user" {
  length  = 32
  special = true
}
```

## PostgreSQL Configuration Flags

Common database flags for optimization:

```hcl
database_flags = [
  # Connection settings
  { name = "max_connections", value = "200" },

  # Memory settings (for 15 GB RAM instance)
  { name = "shared_buffers", value = "3932160" },       # 25% of RAM = 3.75 GB
  { name = "effective_cache_size", value = "11796480" }, # 75% of RAM = 11.25 GB
  { name = "work_mem", value = "32768" },               # 32 MB
  { name = "maintenance_work_mem", value = "1048576" }, # 1 GB

  # Query planning
  { name = "random_page_cost", value = "1.1" },  # For SSD
  { name = "effective_io_concurrency", value = "200" },

  # WAL settings
  { name = "wal_buffers", value = "16384" },  # 16 MB
  { name = "checkpoint_completion_target", value = "0.9" },

  # Logging
  { name = "log_min_duration_statement", value = "1000" },  # Log slow queries (>1s)
  { name = "log_connections", value = "on" },
  { name = "log_disconnections", value = "on" }
]
```

## Machine Tiers

### Shared-core (Low Cost)

- `db-f1-micro`: 1 shared vCPU, 0.6 GB RAM (~$7/month)
- `db-g1-small`: 1 shared vCPU, 1.7 GB RAM (~$25/month)

### Custom Machine Types

- `db-custom-CPU-RAM`: Customize CPU and RAM
- Example: `db-custom-2-7680` = 2 vCPU, 7.5 GB RAM (~$100/month)
- Example: `db-custom-4-15360` = 4 vCPU, 15 GB RAM (~$200/month)
- Example: `db-custom-8-30720` = 8 vCPU, 30 GB RAM (~$400/month)

**RAM per vCPU:** 3.75 GB - 6.5 GB (in increments of 256 MB)

## Backup and Recovery

### Automated Backups

```hcl
enable_backups         = true
backup_start_time      = "03:00"  # Daily at 3 AM UTC
backup_retention_count = 30       # Keep 30 backups
```

**Restore from backup:**

```bash
gcloud sql backups restore BACKUP_ID \
  --backup-instance=SOURCE_INSTANCE \
  --backup-instance-project=PROJECT_ID \
  --instance=TARGET_INSTANCE
```

### Point-in-Time Recovery

```hcl
enable_pitr                    = true
transaction_log_retention_days = 7
```

**Restore to specific time:**

```bash
gcloud sql instances restore-backup INSTANCE_NAME \
  --backup-run=BACKUP_ID \
  --point-in-time=2025-01-19T10:30:00.000Z
```

## High Availability

```hcl
high_availability = true  # REGIONAL instance with automatic failover
```

**How it works:**

- Primary instance in zone A
- Standby replica in zone B (same region)
- Automatic failover if primary fails
- Synchronous replication (no data loss)
- Failover time: ~60-120 seconds

## Private IP Networking

```hcl
enable_public_ip = false
private_network  = "projects/PROJECT/global/networks/VPC_NAME"
```

**Requirements:**

1. VPC network must exist
2. Enable Service Networking API
3. Create private services access connection:

```bash
gcloud compute addresses create google-managed-services-default \
  --global \
  --purpose=VPC_PEERING \
  --prefix-length=16 \
  --network=default

gcloud services vpc-peerings connect \
  --service=servicenetworking.googleapis.com \
  --ranges=google-managed-services-default \
  --network=default
```

## Connecting to Cloud SQL

### Cloud SQL Proxy (Recommended)

```bash
# Download Cloud SQL Proxy
curl -o cloud-sql-proxy https://storage.googleapis.com/cloud-sql-connectors/cloud-sql-proxy/v2.8.0/cloud-sql-proxy.darwin.amd64
chmod +x cloud-sql-proxy

# Start proxy
./cloud-sql-proxy PROJECT:REGION:INSTANCE

# Connect via psql
psql "host=127.0.0.1 port=5432 dbname=DATABASE user=admin"
```

### Direct Connection (Private IP)

```bash
psql "host=PRIVATE_IP port=5432 dbname=DATABASE user=admin sslmode=require"
```

### From Cloud Run

```yaml
env:
  - name: DB_HOST
    value: '/cloudsql/PROJECT:REGION:INSTANCE'
  - name: DB_USER
    value: 'admin'
  - name: DB_PASS
    valueFrom:
      secretKeyRef:
        name: db-password
        key: latest
```

## Inputs

| Name              | Description        | Type           | Default              | Required |
| ----------------- | ------------------ | -------------- | -------------------- | :------: |
| project_id        | GCP project ID     | `string`       | n/a                  |   yes    |
| instance_name     | Instance name      | `string`       | n/a                  |   yes    |
| region            | Instance region    | `string`       | `"us-central1"`      |    no    |
| database_version  | PostgreSQL version | `string`       | `"POSTGRES_15"`      |    no    |
| tier              | Machine type       | `string`       | `"db-custom-2-7680"` |    no    |
| high_availability | Enable HA          | `bool`         | `false`              |    no    |
| disk_size         | Disk size (GB)     | `number`       | `10`                 |    no    |
| enable_backups    | Enable backups     | `bool`         | `true`               |    no    |
| enable_pitr       | Enable PITR        | `bool`         | `true`               |    no    |
| enable_public_ip  | Enable public IP   | `bool`         | `false`              |    no    |
| private_network   | VPC network        | `string`       | `null`               |    no    |
| databases         | Database names     | `list(string)` | `[]`                 |    no    |
| read_replicas     | Read replicas      | `map(object)`  | `{}`                 |    no    |

## Outputs

| Name                     | Description                               |
| ------------------------ | ----------------------------------------- |
| instance_name            | Instance name                             |
| instance_connection_name | Connection name for Cloud SQL Proxy       |
| instance_ip_address      | IP addresses (public/private)             |
| databases                | Created databases                         |
| admin_password_secret    | Secret Manager secret with admin password |

## Cost Estimation

### Small Instance (Development)

- Tier: `db-f1-micro`
- Disk: 10 GB SSD
- **Cost:** ~$10/month

### Medium Instance (Staging)

- Tier: `db-custom-2-7680`
- Disk: 20 GB SSD
- Backups: 7 days
- **Cost:** ~$120/month

### Large HA Instance (Production)

- Tier: `db-custom-4-15360`
- High Availability: Yes
- Disk: 100 GB SSD
- Backups: 30 days
- PITR: 7 days
- **Cost:** ~$400/month

**Cost Factors:**

- Instance tier (CPU/RAM): 70-80%
- Storage: 10-15%
- Backups: 5-10%
- Networking: 5%

## Security Best Practices

1. ✅ **Use private IP** - Avoid public internet exposure
2. ✅ **Require SSL** - Encrypt connections
3. ✅ **Enable deletion protection** - Prevent accidental deletion
4. ✅ **Use Secret Manager** - Store passwords securely
5. ✅ **Limit authorized networks** - If using public IP
6. ✅ **Enable Query Insights** - Monitor for suspicious activity
7. ✅ **Regular backups** - 30-day retention for production
8. ✅ **IAM authentication** - Avoid password-based auth where possible

## Troubleshooting

### Cannot connect to instance

- Check if Cloud SQL Proxy is running
- Verify firewall rules allow connections
- Ensure service account has `cloudsql.client` role

### High memory usage

Increase `shared_buffers` and `effective_cache_size` database flags.

### Slow queries

- Enable Query Insights
- Check `log_min_duration_statement` flag
- Add indexes to frequently queried columns

### Backup failures

- Check available disk space
- Verify backup window doesn't conflict with high traffic

## Requirements

- Terraform >= 1.0
- Google Cloud Provider >= 6.0
- Cloud SQL Admin API enabled
- Service Networking API enabled (for private IP)
