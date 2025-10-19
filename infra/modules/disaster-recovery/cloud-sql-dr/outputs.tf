# Cloud SQL Disaster Recovery - Outputs
# Information about DR replica for monitoring and failover procedures

# ============================================================================
# DR REPLICA INFORMATION
# ============================================================================

output "replica_instance_name" {
  description = "Name of the DR replica instance"
  value       = google_sql_database_instance.dr_replica.name
}

output "replica_instance_id" {
  description = "Full resource ID of the DR replica"
  value       = google_sql_database_instance.dr_replica.id
}

output "replica_connection_name" {
  description = "Connection name for Cloud SQL Proxy"
  value       = google_sql_database_instance.dr_replica.connection_name
}

output "replica_self_link" {
  description = "Self-link of the DR replica instance"
  value       = google_sql_database_instance.dr_replica.self_link
}

# ============================================================================
# NETWORK CONNECTION DETAILS
# ============================================================================

output "replica_ip_addresses" {
  description = "IP addresses of the DR replica"
  value = {
    public_ip  = try(google_sql_database_instance.dr_replica.public_ip_address, null)
    private_ip = try(google_sql_database_instance.dr_replica.private_ip_address, null)
  }
}

output "replica_public_ip" {
  description = "Public IP address of the DR replica (if enabled)"
  value       = try(google_sql_database_instance.dr_replica.public_ip_address, null)
}

output "replica_private_ip" {
  description = "Private IP address of the DR replica (if enabled)"
  value       = try(google_sql_database_instance.dr_replica.private_ip_address, null)
}

# ============================================================================
# DR CONFIGURATION STATUS
# ============================================================================

output "failover_capable" {
  description = "Whether replica is configured as failover target"
  value       = true # Always true for DR replicas
}

output "replica_region" {
  description = "Region where DR replica is deployed"
  value       = var.secondary_region
}

output "availability_type" {
  description = "Availability type of DR replica (ZONAL or REGIONAL)"
  value       = var.replica_high_availability ? "REGIONAL" : "ZONAL"
}

output "replica_tier" {
  description = "Machine tier of DR replica"
  value       = var.replica_tier
}

# ============================================================================
# BACKUP CONFIGURATION
# ============================================================================

output "backups_enabled" {
  description = "Whether backups are enabled on replica"
  value       = var.enable_replica_backups
}

output "pitr_enabled" {
  description = "Whether Point-in-Time Recovery is enabled on replica"
  value       = var.enable_replica_pitr
}

# ============================================================================
# MONITORING ALERTS
# ============================================================================

output "monitoring_alerts" {
  description = "Monitoring alerts configured for DR replica"
  value = var.enable_monitoring ? {
    replica_lag_alert = {
      name      = google_monitoring_alert_policy.replica_lag_high[0].display_name
      id        = google_monitoring_alert_policy.replica_lag_high[0].id
      threshold = "${var.replica_lag_threshold_seconds}s"
    }
    replica_down_alert = {
      name = google_monitoring_alert_policy.replica_down[0].display_name
      id   = google_monitoring_alert_policy.replica_down[0].id
    }
  } : null
}

output "replica_lag_threshold" {
  description = "Configured threshold for replica lag alerts (seconds)"
  value       = var.replica_lag_threshold_seconds
}

# ============================================================================
# COST ESTIMATION
# ============================================================================

output "estimated_monthly_cost_usd" {
  description = "Estimated monthly cost for Cloud SQL DR replica (approximate)"
  value = {
    replica_instance = var.replica_high_availability ? 120 : 60
    disk_cost        = var.disk_size * 0.17 # $0.17/GB for SSD
    backup_cost      = var.enable_replica_backups ? 15 : 0
    network_egress   = 10 # Cross-region replication
    total_min        = var.replica_high_availability ? 145 : 85
    total_max        = var.replica_high_availability ? 180 : 110
    mode             = var.replica_high_availability ? "REGIONAL (High Availability)" : "ZONAL (Cost Optimized)"
    note             = "Costs vary based on tier, disk size, and actual usage. Add ~$10-20/month for cross-region network."
  }
}

# ============================================================================
# DR READINESS
# ============================================================================

output "dr_readiness" {
  description = "DR readiness status for Cloud SQL"
  value = {
    replica_deployed         = true
    failover_target          = true
    monitoring_enabled       = var.enable_monitoring
    backups_enabled          = var.enable_replica_backups
    notifications_configured = length(var.notification_channels) > 0
    deletion_protected       = var.deletion_protection
    ready_for_failover       = true
  }
}

# ============================================================================
# FAILOVER PROCEDURE INFORMATION
# ============================================================================

output "failover_command" {
  description = "Command to promote replica to primary (use during disaster)"
  value       = "gcloud sql instances promote-replica ${google_sql_database_instance.dr_replica.name} --project=${var.project_id}"
  sensitive   = false
}

output "failover_documentation" {
  description = "Path to failover procedure documentation"
  value       = var.create_failover_docs ? "${path.module}/FAILOVER_PROCEDURE.md" : null
}

# ============================================================================
# VALIDATION CHECKLIST
# ============================================================================

output "validation_checklist" {
  description = "Pre-activation validation checklist"
  value = [
    "✅ DR replica deployed in ${var.secondary_region}",
    "✅ Configured as failover target",
    var.enable_monitoring ? "✅ Replica lag monitoring enabled (threshold: ${var.replica_lag_threshold_seconds}s)" : "⚠️ Monitoring not enabled",
    length(var.notification_channels) > 0 ? "✅ Alert notification channels configured" : "⚠️ No notification channels",
    var.enable_replica_backups ? "✅ Replica backups enabled" : "⚠️ Replica backups disabled",
    var.deletion_protection ? "✅ Deletion protection enabled" : "⚠️ Deletion protection disabled",
    var.replica_high_availability ? "💰 REGIONAL HA (higher cost, better availability)" : "💰 ZONAL (lower cost)",
    "⚠️ Manual promotion required for failover (not automatic)"
  ]
}

# ============================================================================
# MONITORING QUERIES
# ============================================================================

output "monitoring_queries" {
  description = "Useful monitoring queries for DR replica"
  value = {
    check_replica_status = "gcloud sql instances describe ${google_sql_database_instance.dr_replica.name} --project=${var.project_id}"
    view_replication_lag = "gcloud sql operations list --instance=${google_sql_database_instance.dr_replica.name} --project=${var.project_id}"
    check_replica_health = "gcloud sql instances get-health ${google_sql_database_instance.dr_replica.name} --project=${var.project_id}"
    list_recent_backups  = "gcloud sql backups list --instance=${google_sql_database_instance.dr_replica.name} --project=${var.project_id}"
  }
}

# ============================================================================
# ACTIVATION INSTRUCTIONS
# ============================================================================

output "activation_instructions" {
  description = "Instructions for activating Cloud SQL DR in production"
  value       = <<-EOT
    # Cloud SQL Disaster Recovery - Activation Instructions

    ## Current Configuration:
    - Primary Instance: ${var.primary_instance_name} (${var.primary_instance_region})
    - DR Replica: ${google_sql_database_instance.dr_replica.name} (${var.secondary_region})
    - Failover Capable: YES
    - Availability: ${var.replica_high_availability ? "REGIONAL" : "ZONAL"}

    ## To Activate in Production:
    1. Ensure primary Cloud SQL instance is healthy and running
    2. Set enable_cloud_sql_dr = true in production terraform.tfvars
    3. Configure notification_channels for alerts
    4. Review estimated costs ($${var.replica_high_availability ? "145-180" : "85-110"}/month)
    5. Run: terraform plan -var-file=production.tfvars
    6. Verify primary_instance_id matches actual primary instance
    7. Run: terraform apply -var-file=production.tfvars
    8. Wait 30-60 minutes for initial replication to complete
    9. Validate replica status: ${self.monitoring_queries.check_replica_status}
    10. Test failover procedure in non-production environment

    ## Monitoring:
    - Check replica lag: ${self.monitoring_queries.view_replication_lag}
    - View alerts: Cloud Console > Monitoring > Alerting
    - Replica dashboard: Cloud Console > SQL > ${google_sql_database_instance.dr_replica.name}

    ## Failover (Emergency Only):
    - Review procedure: ${var.create_failover_docs ? "FAILOVER_PROCEDURE.md" : "docs/deployment/disaster-recovery-runbook.md"}
    - Promotion command: ${self.failover_command}
    - Estimated RTO: 10-15 minutes
    - Estimated RPO: <5 minutes (depends on replica lag)

    ## Cost Optimization:
    - ZONAL replica: Lower cost (~$85-110/month), single-zone availability
    - REGIONAL replica: Higher cost (~$145-180/month), multi-zone HA
    - Recommendation: Start with ZONAL, upgrade to REGIONAL for production

    IMPORTANT: This is a PRODUCTION-ONLY configuration. Do NOT enable in staging.
  EOT
}
