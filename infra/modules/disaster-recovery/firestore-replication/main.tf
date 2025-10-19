# Firestore Multi-Region Replication Sub-Module
# CONFIGURATION ONLY - Demonstrates multi-region Firestore setup for DR
#
# This configuration extends the base Firestore module with multi-region
# capabilities for disaster recovery. Changes database location from single
# region (us-central1) to multi-region (nam5) for automatic cross-region
# replication.
#
# ACTIVATION NOTES:
# - Migrating existing Firestore to multi-region requires data export/import
# - Estimated downtime: 2-4 hours for full migration
# - Cost increase: ~1.5x current Firestore costs
# - RPO: Near-zero (continuous replication)
# - RTO: <5 minutes (automatic failover)

terraform {
  required_version = ">= 1.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.0"
    }
  }
}

# ============================================================================
# MULTI-REGION FIRESTORE DATABASE
# ============================================================================

# Note: This is a TEMPLATE for multi-region Firestore configuration
# To activate:
# 1. Export existing Firestore data using gcloud firestore export
# 2. Delete existing single-region database (or create new database name)
# 3. Apply this configuration with location_id = "nam5" (or other multi-region)
# 4. Import data using gcloud firestore import

resource "google_firestore_database" "multi_region" {
  project = var.project_id
  name    = var.database_name # Use different name during migration

  # CRITICAL: Multi-region location instead of single region
  # nam5 = North America (us-central1, us-east1, us-east4, us-west1, etc.)
  # eur3 = Europe (europe-west1, europe-west4, europe-north1)
  location_id = var.location_id

  # Database type
  type = "FIRESTORE_NATIVE"

  # Concurrency mode - use OPTIMISTIC for multi-region
  concurrency_mode = "OPTIMISTIC"

  # App Engine integration
  app_engine_integration_mode = "DISABLED"

  # Point-in-time recovery (CRITICAL for DR)
  point_in_time_recovery_enablement = "POINT_IN_TIME_RECOVERY_ENABLED"

  # Delete protection (ALWAYS enable for production)
  delete_protection_state = "DELETE_PROTECTION_ENABLED"

  # Deletion policy
  deletion_policy = "ABANDON" # Prevent accidental deletion

  lifecycle {
    prevent_destroy = true
    ignore_changes = [
      # Ignore app_engine_integration_mode if it gets enabled elsewhere
      app_engine_integration_mode
    ]
  }
}

# ============================================================================
# ENHANCED BACKUP SCHEDULE FOR DR
# ============================================================================

# Daily backups with extended retention for DR
resource "google_firestore_backup_schedule" "daily_dr_backup" {
  project  = var.project_id
  database = google_firestore_database.multi_region.name

  # Daily recurrence at 2 AM UTC (low traffic period)
  daily_recurrence {}

  # Extended retention for DR scenarios (90 days default)
  retention = "${var.backup_retention_days * 86400}s"

  depends_on = [google_firestore_database.multi_region]
}

# Weekly full backups for long-term retention
resource "google_firestore_backup_schedule" "weekly_dr_backup" {
  count = var.enable_weekly_backups ? 1 : 0

  project  = var.project_id
  database = google_firestore_database.multi_region.name

  # Weekly recurrence (Sundays at 3 AM UTC)
  weekly_recurrence {
    day = "SUNDAY"
  }

  # Longer retention for weekly backups (180 days = 6 months)
  retention = "${var.weekly_backup_retention_days * 86400}s"

  depends_on = [google_firestore_database.multi_region]
}

# ============================================================================
# EXPORT BUCKET FOR DATA MIGRATION AND DR
# ============================================================================

resource "google_storage_bucket" "firestore_dr_exports" {
  project = var.project_id
  name    = "${var.project_id}-firestore-dr-exports"

  # Use dual-region for exports (faster access, geo-redundancy)
  location      = "US" # Multi-region covering nam5
  storage_class = "STANDARD"

  # Versioning for export history
  versioning {
    enabled = true
  }

  # Lifecycle: Transition old exports to cheaper storage
  lifecycle_rule {
    action {
      type          = "SetStorageClass"
      storage_class = "NEARLINE"
    }
    condition {
      age = 30 # Move to NEARLINE after 30 days
    }
  }

  lifecycle_rule {
    action {
      type          = "SetStorageClass"
      storage_class = "COLDLINE"
    }
    condition {
      age = 90 # Move to COLDLINE after 90 days
    }
  }

  lifecycle_rule {
    action {
      type = "Delete"
    }
    condition {
      age = var.export_retention_days # Delete old exports
    }
  }

  # Uniform bucket-level access for security
  uniform_bucket_level_access = true

  labels = merge(
    var.labels,
    {
      purpose           = "firestore-dr-export"
      disaster_recovery = "enabled"
      managed_by        = "terraform"
    }
  )
}

# Grant Firestore service account access to export bucket
resource "google_storage_bucket_iam_member" "firestore_export_access" {
  bucket = google_storage_bucket.firestore_dr_exports.name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:service-${data.google_project.project.number}@gcp-sa-firestore.iam.gserviceaccount.com"
}

data "google_project" "project" {
  project_id = var.project_id
}

# ============================================================================
# MONITORING FOR FIRESTORE DR
# ============================================================================

# Alert for backup failures (critical for RPO)
resource "google_monitoring_alert_policy" "backup_failure" {
  count = var.enable_monitoring ? 1 : 0

  project      = var.project_id
  display_name = "[Firestore DR] Backup Failure - ${var.database_name}"

  conditions {
    display_name = "Firestore backup failed"

    condition_monitoring_query_language {
      query = <<-EOT
        fetch firestore.googleapis.com/Database
        | metric 'firestore.googleapis.com/database/backup_count'
        | filter (resource.database_id == '${var.database_name}')
        | group_by 5m, [value_backup_count_mean: mean(value.backup_count)]
        | condition value_backup_count_mean == 0
      EOT

      duration = "300s"
    }
  }

  notification_channels = var.notification_channels

  alert_strategy {
    auto_close = "604800s" # 7 days
  }

  documentation {
    content   = <<-EOT
      **DISASTER RECOVERY ALERT: Firestore Backup Failure**

      Firestore database '${var.database_name}' backup has failed.

      **Impact**: RPO target at risk, potential data loss in DR scenario

      **Actions**:
      1. Check backup schedule: gcloud firestore backups list --database=${var.database_name}
      2. Verify IAM permissions for Firestore service account
      3. Check export bucket storage quota
      4. Review Firestore operation logs for errors

      **Escalation**: If backup fails for >24h, escalate to platform team
    EOT
    mime_type = "text/markdown"
  }
}

# ============================================================================
# DOCUMENTATION OUTPUT
# ============================================================================

# Create a text file with migration instructions
resource "local_file" "migration_instructions" {
  count = var.create_migration_docs ? 1 : 0

  filename = "${path.module}/MIGRATION_INSTRUCTIONS.md"
  content  = <<-EOT
    # Firestore Multi-Region Migration Instructions

    ## Pre-Migration Checklist
    - [ ] Schedule maintenance window (2-4 hours)
    - [ ] Notify users of downtime
    - [ ] Verify backup schedule is working
    - [ ] Test export/import in dev environment
    - [ ] Have rollback plan ready

    ## Migration Steps

    ### 1. Export Existing Data
    ```bash
    gcloud firestore export gs://${var.project_id}-firestore-dr-exports/migration-$(date +%Y%m%d) \
      --project=${var.project_id} \
      --database=${var.database_name}
    ```

    ### 2. Verify Export
    ```bash
    gsutil ls -r gs://${var.project_id}-firestore-dr-exports/migration-*
    ```

    ### 3. Delete Existing Database (WARNING: DESTRUCTIVE)
    ```bash
    # ONLY DO THIS AFTER SUCCESSFUL EXPORT VERIFICATION
    gcloud firestore databases delete ${var.database_name} \
      --project=${var.project_id}
    ```

    ### 4. Create Multi-Region Database
    ```bash
    # Apply this Terraform configuration
    terraform apply
    ```

    ### 5. Import Data
    ```bash
    gcloud firestore import gs://${var.project_id}-firestore-dr-exports/migration-YYYYMMDD \
      --project=${var.project_id} \
      --database=${var.database_name}
    ```

    ### 6. Verify Data Integrity
    ```bash
    # Compare document counts before and after
    # Run data validation queries
    # Test application functionality
    ```

    ### 7. Update Security Rules
    ```bash
    # Security rules must be redeployed after migration
    gcloud firestore rules deploy firestore.rules \
      --project=${var.project_id} \
      --database=${var.database_name}
    ```

    ## Rollback Procedure
    If migration fails:
    1. Create new single-region database with original location
    2. Import from backup export
    3. Redeploy security rules
    4. Resume normal operations

    ## Post-Migration
    - [ ] Verify all applications are connecting successfully
    - [ ] Monitor replication lag (should be near-zero)
    - [ ] Confirm backup schedule is running
    - [ ] Update monitoring dashboards
    - [ ] Document migration completion date

    ## Support
    Contact: infrastructure-team@adyela.care
    Runbook: docs/deployment/disaster-recovery-runbook.md
  EOT
}
