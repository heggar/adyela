# Disaster Recovery Module - Main Configuration
# CONFIGURATION ONLY - NOT DEPLOYED TO STAGING
#
# This module orchestrates disaster recovery infrastructure across multiple regions
# for production environments. It provides automated failover capabilities with
# RTO <15min and RPO <1hour.
#
# ACTIVATION: Only enable in production when real users and SLA commitments exist
# COST IMPACT: ~$300-500/month additional when activated

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
# MULTI-REGION CLOUD RUN DEPLOYMENT
# ============================================================================

module "multi_region_cloud_run" {
  source = "./multi-region-cloud-run"
  count  = var.enable_cloud_run_dr ? 1 : 0

  project_id  = var.project_id
  environment = var.environment

  # Regional configuration
  primary_region   = var.primary_region
  secondary_region = var.secondary_region

  # Services to deploy in secondary region (standby)
  services = var.cloud_run_services

  # Failover configuration
  min_secondary_instances = var.min_secondary_instances
  health_check_path       = var.health_check_path
  failover_threshold      = var.failover_threshold

  labels = merge(
    var.labels,
    {
      component = "disaster-recovery"
      dr-type   = "multi-region-cloud-run"
    }
  )
}

# ============================================================================
# FIRESTORE MULTI-REGION REPLICATION
# ============================================================================

module "firestore_replication" {
  source = "./firestore-replication"
  count  = var.enable_firestore_dr ? 1 : 0

  project_id = var.project_id

  # Multi-region configuration
  # Options: nam5 (North America), eur3 (Europe), etc.
  location_id = var.firestore_multi_region_location

  # Consistency model for DR
  # "STRONG" for immediate consistency (recommended for DR)
  # "EVENTUAL" for lower cost but potential data lag
  consistency_model = var.firestore_consistency_model

  # Backup configuration
  enable_backups        = true
  backup_retention_days = var.dr_backup_retention_days

  labels = merge(
    var.labels,
    {
      component = "disaster-recovery"
      dr-type   = "firestore-multi-region"
    }
  )
}

# ============================================================================
# CLOUD SQL CROSS-REGION READ REPLICAS
# ============================================================================

module "cloud_sql_dr" {
  source = "./cloud-sql-dr"
  count  = var.enable_cloud_sql_dr ? 1 : 0

  project_id  = var.project_id
  environment = var.environment

  # Primary instance to replicate
  primary_instance_name = var.cloud_sql_primary_instance

  # Secondary region for replicas
  secondary_region = var.secondary_region

  # Read replica configuration
  replica_tier           = var.cloud_sql_replica_tier
  replica_disk_size      = var.cloud_sql_replica_disk_size
  enable_failover_target = true # Allow promotion to primary

  # High availability settings
  enable_pitr                    = true
  transaction_log_retention_days = 7

  labels = merge(
    var.labels,
    {
      component = "disaster-recovery"
      dr-type   = "cloud-sql-replica"
    }
  )
}

# ============================================================================
# CROSS-REGION STORAGE REPLICATION
# ============================================================================

module "cross_region_storage" {
  source = "./cross-region-storage"
  count  = var.enable_storage_dr ? 1 : 0

  project_id = var.project_id

  # Buckets to replicate
  buckets = var.storage_buckets_for_dr

  # Dual-region or multi-region configuration
  # Dual-region: Lower latency, higher cost (e.g., "US-CENTRAL1+US-EAST1")
  # Multi-region: Higher availability, moderate cost (e.g., "US", "EU")
  replication_type = var.storage_replication_type
  location         = var.storage_dr_location

  # Turbo replication for RPO <15 minutes
  enable_turbo_replication = var.enable_storage_turbo_replication

  # Lifecycle policies for cost optimization
  lifecycle_rules = var.storage_dr_lifecycle_rules

  labels = merge(
    var.labels,
    {
      component = "disaster-recovery"
      dr-type   = "cross-region-storage"
    }
  )
}

# ============================================================================
# DISASTER RECOVERY MONITORING
# ============================================================================

# Alert policy for replica lag (RPO monitoring)
resource "google_monitoring_alert_policy" "replica_lag" {
  count = var.enable_cloud_sql_dr && var.enable_dr_monitoring ? 1 : 0

  project      = var.project_id
  display_name = "[DR] Cloud SQL Replica Lag - ${var.environment}"

  conditions {
    display_name = "Replica lag exceeds RPO target"

    condition_threshold {
      filter          = "resource.type=\"cloudsql_database\" AND metric.type=\"cloudsql.googleapis.com/database/replication/replica_lag\""
      duration        = "300s" # 5 minutes
      comparison      = "COMPARISON_GT"
      threshold_value = var.rpo_minutes * 60 # Convert minutes to seconds

      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_MAX"
      }
    }
  }

  notification_channels = var.dr_notification_channels

  alert_strategy {
    auto_close = "86400s" # 24 hours
  }

  documentation {
    content   = <<-EOT
      **DISASTER RECOVERY ALERT**

      Cloud SQL replica lag has exceeded the RPO target of ${var.rpo_minutes} minutes.

      **Impact**: Potential data loss in DR scenario
      **RTO**: <15 minutes
      **RPO**: <${var.rpo_minutes} minutes (currently exceeded)

      **Actions**:
      1. Check replica health: gcloud sql operations list --instance=[REPLICA]
      2. Verify network connectivity between regions
      3. Review transaction volume on primary
      4. Consider scaling up replica if persistent

      **Escalation**: If lag continues >30min, page infrastructure on-call
    EOT
    mime_type = "text/markdown"
  }
}

# Alert policy for failover service unavailability (RTO monitoring)
resource "google_monitoring_alert_policy" "secondary_service_down" {
  count = var.enable_cloud_run_dr && var.enable_dr_monitoring ? 1 : 0

  project      = var.project_id
  display_name = "[DR] Secondary Region Service Down - ${var.environment}"

  conditions {
    display_name = "Secondary region service unavailable"

    condition_threshold {
      filter          = "resource.type=\"cloud_run_revision\" AND resource.labels.location=\"${var.secondary_region}\" AND metric.type=\"run.googleapis.com/container/cpu/utilizations\""
      duration        = "180s" # 3 minutes
      comparison      = "COMPARISON_LT"
      threshold_value = 0.01 # Effectively no activity

      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_MEAN"
      }
    }
  }

  notification_channels = var.dr_notification_channels

  alert_strategy {
    auto_close = "3600s" # 1 hour
  }

  documentation {
    content   = <<-EOT
      **DISASTER RECOVERY ALERT**

      Secondary region (${var.secondary_region}) Cloud Run service is down.

      **Impact**: DR failover capability compromised
      **RTO**: Cannot meet <15min target if primary fails

      **Actions**:
      1. Check service status: gcloud run services describe [SERVICE] --region=${var.secondary_region}
      2. Verify last deployment was successful
      3. Check service account permissions
      4. Review Cloud Run logs for errors

      **Escalation**: IMMEDIATE - DR capability is critical for SLA compliance
    EOT
    mime_type = "text/markdown"
  }
}

# Dashboard for DR metrics
resource "google_monitoring_dashboard" "disaster_recovery" {
  count = var.enable_dr_monitoring ? 1 : 0

  project = var.project_id
  dashboard_json = jsonencode({
    displayName = "Disaster Recovery - ${title(var.environment)}"
    mosaicLayout = {
      columns = 12
      tiles = [
        {
          width  = 6
          height = 4
          widget = {
            title = "Cloud SQL Replica Lag (RPO)"
            xyChart = {
              dataSets = [{
                timeSeriesQuery = {
                  timeSeriesFilter = {
                    filter = "resource.type=\"cloudsql_database\" AND metric.type=\"cloudsql.googleapis.com/database/replication/replica_lag\""
                    aggregation = {
                      alignmentPeriod  = "60s"
                      perSeriesAligner = "ALIGN_MEAN"
                    }
                  }
                }
              }]
              yAxis = {
                label = "Lag (seconds)"
                scale = "LINEAR"
              }
            }
          }
        },
        {
          width  = 6
          height = 4
          widget = {
            title = "Secondary Region Service Health"
            xyChart = {
              dataSets = [{
                timeSeriesQuery = {
                  timeSeriesFilter = {
                    filter = "resource.type=\"cloud_run_revision\" AND resource.labels.location=\"${var.secondary_region}\" AND metric.type=\"run.googleapis.com/request_count\""
                    aggregation = {
                      alignmentPeriod  = "60s"
                      perSeriesAligner = "ALIGN_RATE"
                    }
                  }
                }
              }]
              yAxis = {
                label = "Requests/sec"
                scale = "LINEAR"
              }
            }
          }
        },
        {
          width  = 12
          height = 4
          widget = {
            title = "DR Storage Replication Status"
            xyChart = {
              dataSets = [{
                timeSeriesQuery = {
                  timeSeriesFilter = {
                    filter = "resource.type=\"gcs_bucket\" AND metric.type=\"storage.googleapis.com/storage/total_bytes\""
                    aggregation = {
                      alignmentPeriod    = "300s"
                      perSeriesAligner   = "ALIGN_MEAN"
                      crossSeriesReducer = "REDUCE_SUM"
                      groupByFields      = ["resource.location"]
                    }
                  }
                }
              }]
              yAxis = {
                label = "Storage (bytes)"
                scale = "LINEAR"
              }
            }
          }
        }
      ]
    }
  })
}

# ============================================================================
# COST TRACKING LABELS
# ============================================================================

# Tag all DR resources for cost attribution
locals {
  dr_labels = merge(
    var.labels,
    {
      disaster-recovery = "enabled"
      rto-target        = "${var.rto_minutes}min"
      rpo-target        = "${var.rpo_minutes}min"
      dr-activation     = formatdate("YYYY-MM-DD", timestamp())
      cost-center       = "infrastructure-dr"
    }
  )
}
