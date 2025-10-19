# Cross-Region Storage Disaster Recovery Sub-Module
# CONFIGURATION ONLY - FOR PRODUCTION ACTIVATION ONLY
#
# This module creates dual-region or multi-region Cloud Storage buckets with
# versioning, turbo replication, and lifecycle management for disaster recovery.
#
# ACTIVATION NOTES:
# - Dual-region: 2 specific regions (e.g., NAM4 = Iowa + South Carolina)
# - Multi-region: Continent-wide (e.g., US = all US regions)
# - Turbo replication: RPO <15 minutes (additional cost)
# - Cost: ~$30-60/month for dual-region, ~$50-100/month for multi-region

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
# DUAL/MULTI-REGION STORAGE BUCKETS FOR DR
# ============================================================================

# Create geo-redundant storage buckets for critical data
resource "google_storage_bucket" "dr_bucket" {
  for_each = { for bucket in var.buckets : bucket.name => bucket }

  project  = var.project_id
  name     = each.value.name
  location = var.dr_location # Dual-region (e.g., NAM4) or Multi-region (e.g., US)

  # Storage class
  storage_class = lookup(each.value, "storage_class", "STANDARD")

  # Force destroy (set to false for production to prevent accidental deletion)
  force_destroy = var.allow_force_destroy

  # ============================================================================
  # VERSIONING (CRITICAL FOR DR)
  # ============================================================================

  versioning {
    enabled = lookup(each.value, "versioning", true) # Always enabled for DR
  }

  # ============================================================================
  # TURBO REPLICATION (OPTIONAL - FOR STRICT RPO)
  # ============================================================================

  # Enable turbo replication for RPO <15 minutes (additional cost)
  dynamic "custom_placement_config" {
    for_each = var.enable_turbo_replication && var.replication_type == "dual-region" ? [1] : []
    content {
      data_locations = var.turbo_replication_regions
    }
  }

  # ============================================================================
  # LIFECYCLE RULES FOR COST OPTIMIZATION
  # ============================================================================

  # Transition to NEARLINE after 30 days
  lifecycle_rule {
    action {
      type          = "SetStorageClass"
      storage_class = "NEARLINE"
    }
    condition {
      age                   = 30
      matches_storage_class = ["STANDARD"]
    }
  }

  # Transition to COLDLINE after 90 days
  lifecycle_rule {
    action {
      type          = "SetStorageClass"
      storage_class = "COLDLINE"
    }
    condition {
      age                   = 90
      matches_storage_class = ["NEARLINE"]
    }
  }

  # Delete old versions after retention period
  lifecycle_rule {
    action {
      type = "Delete"
    }
    condition {
      age                = var.version_retention_days
      num_newer_versions = 3 # Keep latest 3 versions
      with_state         = "ARCHIVED"
    }
  }

  # Delete incomplete multipart uploads after 7 days
  lifecycle_rule {
    action {
      type = "AbortIncompleteMultipartUpload"
    }
    condition {
      age = 7
    }
  }

  # Custom lifecycle rules from variable
  dynamic "lifecycle_rule" {
    for_each = lookup(each.value, "lifecycle_rules", [])
    content {
      action {
        type          = lifecycle_rule.value.action.type
        storage_class = lookup(lifecycle_rule.value.action, "storage_class", null)
      }
      condition {
        age                        = lookup(lifecycle_rule.value.condition, "age", null)
        created_before             = lookup(lifecycle_rule.value.condition, "created_before", null)
        with_state                 = lookup(lifecycle_rule.value.condition, "with_state", null)
        matches_storage_class      = lookup(lifecycle_rule.value.condition, "matches_storage_class", null)
        num_newer_versions         = lookup(lifecycle_rule.value.condition, "num_newer_versions", null)
        days_since_noncurrent_time = lookup(lifecycle_rule.value.condition, "days_since_noncurrent_time", null)
      }
    }
  }

  # ============================================================================
  # SECURITY CONFIGURATION
  # ============================================================================

  # Uniform bucket-level access (recommended)
  uniform_bucket_level_access = true

  # Public access prevention (always enforced for production)
  public_access_prevention = "enforced"

  # ============================================================================
  # ENCRYPTION (CMEK RECOMMENDED FOR COMPLIANCE)
  # ============================================================================

  dynamic "encryption" {
    for_each = var.kms_key_name != null ? [1] : []
    content {
      default_kms_key_name = var.kms_key_name
    }
  }

  # ============================================================================
  # CORS (IF NEEDED FOR WEB ACCESS)
  # ============================================================================

  dynamic "cors" {
    for_each = lookup(each.value, "enable_cors", false) ? [1] : []
    content {
      origin          = lookup(each.value, "cors_origins", ["*"])
      method          = lookup(each.value, "cors_methods", ["GET", "HEAD"])
      response_header = ["*"]
      max_age_seconds = 3600
    }
  }

  # ============================================================================
  # LOGGING (AUDIT ACCESS FOR COMPLIANCE)
  # ============================================================================

  dynamic "logging" {
    for_each = var.access_logging_bucket != null ? [1] : []
    content {
      log_bucket        = var.access_logging_bucket
      log_object_prefix = "${each.value.name}/"
    }
  }

  # ============================================================================
  # LABELS FOR DR TRACKING
  # ============================================================================

  labels = merge(
    var.labels,
    {
      disaster_recovery = "enabled"
      dr_component      = "cross-region-storage"
      replication_type  = var.replication_type
      turbo_replication = var.enable_turbo_replication ? "enabled" : "disabled"
      versioning        = lookup(each.value, "versioning", true) ? "enabled" : "disabled"
      managed_by        = "terraform"
    }
  )

  # ============================================================================
  # LIFECYCLE POLICY
  # ============================================================================

  lifecycle {
    prevent_destroy = var.prevent_bucket_destroy
    ignore_changes = [
      # Ignore automatic encryption changes
      encryption
    ]
  }
}

# ============================================================================
# IAM BINDINGS FOR BUCKET ACCESS
# ============================================================================

# Grant object viewer role to specified members
resource "google_storage_bucket_iam_member" "object_viewers" {
  for_each = { for binding in local.viewer_bindings : "${binding.bucket}-${binding.member}" => binding }

  bucket = google_storage_bucket.dr_bucket[each.value.bucket].name
  role   = "roles/storage.objectViewer"
  member = each.value.member
}

# Grant object admin role to specified members
resource "google_storage_bucket_iam_member" "object_admins" {
  for_each = { for binding in local.admin_bindings : "${binding.bucket}-${binding.member}" => binding }

  bucket = google_storage_bucket.dr_bucket[each.value.bucket].name
  role   = "roles/storage.objectAdmin"
  member = each.value.member
}

# ============================================================================
# MONITORING FOR REPLICATION STATUS
# ============================================================================

# Alert when bucket is approaching quota (if set)
resource "google_monitoring_alert_policy" "bucket_quota_alert" {
  for_each = var.enable_monitoring ? { for bucket in var.buckets : bucket.name => bucket if lookup(bucket, "quota_gb", 0) > 0 } : {}

  project      = var.project_id
  display_name = "[DR] Storage Quota Alert - ${each.value.name}"

  conditions {
    display_name = "Bucket approaching ${lookup(each.value, "quota_gb", 0)}GB quota"

    condition_threshold {
      filter = "resource.type=\"gcs_bucket\" AND resource.labels.bucket_name=\"${each.value.name}\" AND metric.type=\"storage.googleapis.com/storage/total_bytes\""

      duration   = "300s"
      comparison = "COMPARISON_GT"
      # Alert at 80% of quota
      threshold_value = lookup(each.value, "quota_gb", 0) * 0.8 * 1073741824 # Convert GB to bytes

      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_MEAN"
      }
    }
  }

  notification_channels = var.notification_channels

  alert_strategy {
    auto_close = "86400s" # 24 hours
  }

  documentation {
    content   = <<-EOT
      **DISASTER RECOVERY ALERT: Storage Quota Warning**

      DR bucket '${each.value.name}' is approaching configured quota limit.

      **Current Quota**: ${lookup(each.value, "quota_gb", 0)}GB
      **Alert Threshold**: 80%

      **Impact**: May affect backup operations or data replication

      **Actions**:
      1. Check bucket size: gsutil du -sh gs://${each.value.name}
      2. Review lifecycle rules: gsutil lifecycle get gs://${each.value.name}
      3. Identify large objects: gsutil ls -lh gs://${each.value.name}/** | sort -k1 -h
      4. Consider increasing quota or cleaning up old data
      5. Verify lifecycle rules are working: Check NEARLINE/COLDLINE transitions

      **Escalation**: If quota exceeded, backups may fail
    EOT
    mime_type = "text/markdown"
  }
}

# ============================================================================
# LOCAL VARIABLES FOR IAM BINDINGS
# ============================================================================

locals {
  # Flatten viewer bindings
  viewer_bindings = flatten([
    for bucket in var.buckets : [
      for member in lookup(bucket, "viewer_members", []) : {
        bucket = bucket.name
        member = member
      }
    ]
  ])

  # Flatten admin bindings
  admin_bindings = flatten([
    for bucket in var.buckets : [
      for member in lookup(bucket, "admin_members", []) : {
        bucket = bucket.name
        member = member
      }
    ]
  ])
}
