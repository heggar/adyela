# Cloud SQL Disaster Recovery Sub-Module
# CONFIGURATION ONLY - FOR PRODUCTION ACTIVATION ONLY
#
# This module creates cross-region Cloud SQL read replicas configured as failover
# targets for disaster recovery. Replicas can be promoted to primary in case of
# regional failure.
#
# ACTIVATION NOTES:
# - Creating replicas requires PRIMARY instance to exist first
# - Estimated setup time: 30-60 minutes for initial replication
# - Cost: ~$60-150/month per replica (depends on tier)
# - RPO: <5 minutes (near real-time replication)
# - RTO: <10 minutes (manual promotion required)

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
# CROSS-REGION READ REPLICA FOR DISASTER RECOVERY
# ============================================================================

# Create DR replica in secondary region with failover capability
resource "google_sql_database_instance" "dr_replica" {
  project = var.project_id
  name    = "${var.primary_instance_name}-dr-${var.secondary_region}"
  region  = var.secondary_region

  # Link to primary instance
  master_instance_name = var.primary_instance_id

  # Database version must match primary
  database_version = var.database_version

  # CRITICAL: Configure as failover target for DR
  replica_configuration {
    failover_target = true # Can be promoted to primary during disaster
  }

  settings {
    # Machine tier (should match or exceed primary for production DR)
    tier = var.replica_tier

    # Availability type (ZONAL for cost optimization in standby mode)
    availability_type = var.replica_high_availability ? "REGIONAL" : "ZONAL"

    # Disk configuration
    disk_type       = var.disk_type
    disk_size       = var.disk_size
    disk_autoresize = true

    # Disk autoresize limit to prevent cost overruns
    disk_autoresize_limit = var.disk_autoresize_limit

    # IP configuration (must match primary for seamless failover)
    ip_configuration {
      ipv4_enabled    = var.enable_public_ip
      private_network = var.private_network
      require_ssl     = var.require_ssl

      # Copy authorized networks from primary (if using public IP)
      dynamic "authorized_networks" {
        for_each = var.authorized_networks
        content {
          name  = authorized_networks.value.name
          value = authorized_networks.value.cidr
        }
      }
    }

    # Insights configuration for performance monitoring
    insights_config {
      query_insights_enabled  = var.enable_query_insights
      query_string_length     = 1024
      record_application_tags = true
      record_client_address   = true
    }

    # Backup configuration (optional for replicas, but recommended for DR)
    backup_configuration {
      enabled                        = var.enable_replica_backups
      start_time                     = var.backup_start_time
      point_in_time_recovery_enabled = var.enable_replica_pitr
      transaction_log_retention_days = 7

      backup_retention_settings {
        retained_backups = var.backup_retention_count
        retention_unit   = "COUNT"
      }
    }

    # Maintenance window (schedule during low-traffic periods)
    maintenance_window {
      day          = var.maintenance_window_day
      hour         = var.maintenance_window_hour
      update_track = "stable"
    }

    # Database flags (should match primary)
    dynamic "database_flags" {
      for_each = var.database_flags
      content {
        name  = database_flags.value.name
        value = database_flags.value.value
      }
    }

    # Labels for DR tracking
    user_labels = merge(
      var.labels,
      {
        disaster_recovery = "enabled"
        dr_component      = "cloud-sql-replica"
        dr_region         = var.secondary_region
        failover_capable  = "true"
        replica_of        = var.primary_instance_name
        managed_by        = "terraform"
      }
    )
  }

  # Deletion protection (ALWAYS enable for production DR)
  deletion_protection = var.deletion_protection

  lifecycle {
    prevent_destroy = false
    ignore_changes = [
      # Ignore these as they may be updated by GCP
      settings[0].version,
      settings[0].activation_policy
    ]
  }
}

# ============================================================================
# MONITORING FOR REPLICA LAG (CRITICAL FOR RPO)
# ============================================================================

# Alert when replica lag exceeds threshold (risk of data loss if primary fails)
resource "google_monitoring_alert_policy" "replica_lag_high" {
  count = var.enable_monitoring ? 1 : 0

  project      = var.project_id
  display_name = "[DR] Cloud SQL Replica Lag High - ${var.primary_instance_name}"

  conditions {
    display_name = "Replica lag exceeds ${var.replica_lag_threshold_seconds} seconds"

    condition_threshold {
      filter = "resource.type=\"cloudsql_database\" AND resource.labels.database_id=\"${var.project_id}:${google_sql_database_instance.dr_replica.name}\" AND metric.type=\"cloudsql.googleapis.com/database/replication/replica_lag\""

      duration        = "300s" # 5 minutes sustained lag
      comparison      = "COMPARISON_GT"
      threshold_value = var.replica_lag_threshold_seconds

      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_MAX"
      }
    }
  }

  notification_channels = var.notification_channels

  alert_strategy {
    auto_close = "3600s"
  }

  documentation {
    content   = <<-EOT
      **DISASTER RECOVERY ALERT: Cloud SQL Replica Lag**

      DR replica '${google_sql_database_instance.dr_replica.name}' in ${var.secondary_region} is lagging by more than ${var.replica_lag_threshold_seconds} seconds.

      **Impact**: RPO target at risk, potential data loss in DR scenario

      **Potential Causes**:
      - High write volume on primary
      - Network issues between regions
      - Insufficient replica resources
      - Long-running transactions

      **Actions**:
      1. Check replica status: gcloud sql instances describe ${google_sql_database_instance.dr_replica.name}
      2. View replication lag: gcloud sql operations list --instance=${google_sql_database_instance.dr_replica.name}
      3. Check primary write volume: Review Cloud SQL metrics dashboard
      4. Consider increasing replica tier if consistently lagging
      5. Review long-running queries on primary

      **Escalation**: If lag persists >30 minutes, escalate to database team
    EOT
    mime_type = "text/markdown"
  }
}

# Alert when replica is down (DR capability compromised)
resource "google_monitoring_alert_policy" "replica_down" {
  count = var.enable_monitoring ? 1 : 0

  project      = var.project_id
  display_name = "[DR] Cloud SQL Replica Down - ${var.primary_instance_name}"

  conditions {
    display_name = "DR replica is not running"

    condition_threshold {
      filter = "resource.type=\"cloudsql_database\" AND resource.labels.database_id=\"${var.project_id}:${google_sql_database_instance.dr_replica.name}\" AND metric.type=\"cloudsql.googleapis.com/database/up\""

      duration        = "180s" # 3 minutes down
      comparison      = "COMPARISON_LT"
      threshold_value = 1

      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_MIN"
      }
    }
  }

  notification_channels = var.notification_channels

  alert_strategy {
    auto_close = "1800s"
  }

  documentation {
    content   = <<-EOT
      **DISASTER RECOVERY ALERT: Cloud SQL Replica Down**

      DR replica '${google_sql_database_instance.dr_replica.name}' in ${var.secondary_region} is down.

      **Impact**: DR failover capability compromised, cannot meet RTO target

      **Actions**:
      1. Check instance status: gcloud sql instances describe ${google_sql_database_instance.dr_replica.name}
      2. View recent operations: gcloud sql operations list --instance=${google_sql_database_instance.dr_replica.name}
      3. Check for maintenance windows
      4. Review Cloud SQL operation logs for errors
      5. Restart replica if needed: gcloud sql instances restart ${google_sql_database_instance.dr_replica.name}

      **Escalation**: IMMEDIATE - DR capability is critical for production SLA
    EOT
    mime_type = "text/markdown"
  }
}

# ============================================================================
# FAILOVER PROMOTION INSTRUCTIONS (MANUAL PROCEDURE)
# ============================================================================

# Note: This is a MANUAL procedure triggered during actual disaster scenarios
# Automated failover is NOT recommended due to risk of split-brain scenarios

resource "local_file" "failover_procedure" {
  count = var.create_failover_docs ? 1 : 0

  filename = "${path.module}/FAILOVER_PROCEDURE.md"
  content  = <<-EOT
    # Cloud SQL Disaster Recovery - Failover Procedure

    ## Pre-Failover Checklist
    - [ ] Confirm primary region is truly unavailable (not transient issue)
    - [ ] Verify replica is healthy and up-to-date
    - [ ] Check replica lag (should be <${var.replica_lag_threshold_seconds}s)
    - [ ] Notify stakeholders of planned failover
    - [ ] Have rollback plan ready

    ## Primary Instance Status
    **Primary**: ${var.primary_instance_name} (${var.primary_instance_region})
    **Replica**: ${google_sql_database_instance.dr_replica.name} (${var.secondary_region})

    ## Failover Steps

    ### 1. Check Replica Lag
    ```bash
    gcloud sql instances describe ${google_sql_database_instance.dr_replica.name} \
      --project=${var.project_id} \
      --format="value(replicaConfiguration.failoverTarget, state)"
    ```

    Expected output: `True RUNNABLE`

    ### 2. Verify Replica Health
    ```bash
    gcloud sql operations list \
      --instance=${google_sql_database_instance.dr_replica.name} \
      --project=${var.project_id} \
      --limit=5
    ```

    Look for any failed operations or errors.

    ### 3. Promote Replica to Primary (IRREVERSIBLE)
    ```bash
    gcloud sql instances promote-replica ${google_sql_database_instance.dr_replica.name} \
      --project=${var.project_id}
    ```

    **WARNING**: This is irreversible! The replica will become a standalone primary instance.

    ### 4. Update Application Connection Strings
    ```bash
    # New connection string after promotion:
    # Host: <promoted-instance-ip>
    # Port: 5432
    # Database: <database-name>
    # User: <user-name>
    # Password: <from-secret-manager>
    ```

    ### 5. Verify Application Connectivity
    ```bash
    # Test connection from application
    psql -h <promoted-instance-ip> -U <user> -d <database> -c "SELECT version();"
    ```

    ### 6. Update DNS/Load Balancer (if applicable)
    Point application traffic to new primary instance.

    ### 7. Monitor New Primary
    ```bash
    gcloud sql instances describe ${google_sql_database_instance.dr_replica.name} \
      --project=${var.project_id}
    ```

    Verify:
    - State: RUNNABLE
    - Availability: ${var.replica_high_availability ? "REGIONAL" : "ZONAL"}
    - Backups: Enabled

    ## Post-Failover

    ### Create New DR Replica
    Once primary region is restored:
    1. Create new replica in original region (now becomes DR region)
    2. Update Terraform configuration
    3. Test failback procedure in non-production environment

    ## Rollback (if failover was mistake)

    **CRITICAL**: If promotion was accidental, you CANNOT undo it.

    Options:
    1. Create new replica from promoted instance
    2. Restore from backup to new instance
    3. Set up replication from new primary

    ## Support Contacts
    - Database Team: db-team@adyela.care
    - On-Call: [PagerDuty link]
    - Documentation: docs/deployment/disaster-recovery-runbook.md

    ## Estimated Timings
    - Replica promotion: 2-5 minutes
    - Application updates: 5-10 minutes
    - DNS propagation: 1-5 minutes
    - Total RTO: ~10-15 minutes
  EOT
}
