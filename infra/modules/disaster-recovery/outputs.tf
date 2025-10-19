# Disaster Recovery Module - Outputs
# Information for DR activation validation and monitoring

# ============================================================================
# DR STATUS AND ACTIVATION INFO
# ============================================================================

output "dr_enabled" {
  description = "Whether disaster recovery is currently enabled"
  value = (
    var.enable_cloud_run_dr ||
    var.enable_firestore_dr ||
    var.enable_cloud_sql_dr ||
    var.enable_storage_dr
  )
}

output "dr_components_enabled" {
  description = "Which DR components are currently enabled"
  value = {
    cloud_run  = var.enable_cloud_run_dr
    firestore  = var.enable_firestore_dr
    cloud_sql  = var.enable_cloud_sql_dr
    storage    = var.enable_storage_dr
    monitoring = var.enable_dr_monitoring
  }
}

output "dr_targets" {
  description = "RTO and RPO targets for disaster recovery"
  value = {
    rto_minutes = var.rto_minutes
    rpo_minutes = var.rpo_minutes
    rto_target  = "${var.rto_minutes} minutes"
    rpo_target  = "${var.rpo_minutes} minutes"
  }
}

# ============================================================================
# REGIONAL CONFIGURATION
# ============================================================================

output "regions" {
  description = "Primary and secondary regions for DR"
  value = {
    primary   = var.primary_region
    secondary = var.secondary_region
  }
}

# ============================================================================
# CLOUD RUN DR OUTPUTS
# ============================================================================

output "secondary_cloud_run_services" {
  description = "Cloud Run services deployed in secondary region"
  value = var.enable_cloud_run_dr ? {
    region       = var.secondary_region
    services     = [for svc in var.cloud_run_services : svc.name]
    standby_mode = var.min_secondary_instances == 0 ? "cold" : "warm"
  } : null
}

# ============================================================================
# FIRESTORE DR OUTPUTS
# ============================================================================

output "firestore_dr_config" {
  description = "Firestore disaster recovery configuration"
  value = var.enable_firestore_dr ? {
    location         = var.firestore_multi_region_location
    consistency      = var.firestore_consistency_model
    backup_retention = "${var.dr_backup_retention_days} days"
  } : null
}

# ============================================================================
# CLOUD SQL DR OUTPUTS
# ============================================================================

output "cloud_sql_replicas" {
  description = "Cloud SQL read replicas for DR"
  value = var.enable_cloud_sql_dr ? {
    primary_instance = var.cloud_sql_primary_instance
    replica_region   = var.secondary_region
    replica_tier     = var.cloud_sql_replica_tier
    failover_capable = true
  } : null
}

# ============================================================================
# STORAGE DR OUTPUTS
# ============================================================================

output "storage_dr_config" {
  description = "Storage disaster recovery configuration"
  value = var.enable_storage_dr ? {
    replication_type  = var.storage_replication_type
    location          = var.storage_dr_location
    turbo_replication = var.enable_storage_turbo_replication
    buckets_protected = length(var.storage_buckets_for_dr)
  } : null
}

# ============================================================================
# MONITORING AND ALERTING OUTPUTS
# ============================================================================

output "monitoring_dashboard_url" {
  description = "URL to DR monitoring dashboard"
  value = var.enable_dr_monitoring ? (
    "https://console.cloud.google.com/monitoring/dashboards?project=${var.project_id}"
  ) : null
}

output "alert_policies_configured" {
  description = "Number of alert policies configured for DR"
  value = var.enable_dr_monitoring ? (
    (var.enable_cloud_sql_dr ? 1 : 0) +
    (var.enable_cloud_run_dr ? 1 : 0)
  ) : 0
}

# ============================================================================
# COST ESTIMATES
# ============================================================================

output "estimated_monthly_cost_usd" {
  description = "Estimated monthly cost for DR infrastructure (approximate)"
  value = {
    cloud_run_dr = var.enable_cloud_run_dr ? (var.min_secondary_instances > 0 ? 80 : 20) : 0
    firestore_dr = var.enable_firestore_dr ? 50 : 0
    cloud_sql_dr = var.enable_cloud_sql_dr ? 60 : 0
    storage_dr   = var.enable_storage_dr ? 30 : 0
    monitoring   = var.enable_dr_monitoring ? 15 : 0
    total_min    = var.enable_cloud_run_dr || var.enable_firestore_dr || var.enable_cloud_sql_dr || var.enable_storage_dr ? 200 : 0
    total_max    = var.enable_cloud_run_dr || var.enable_firestore_dr || var.enable_cloud_sql_dr || var.enable_storage_dr ? 500 : 0
    note         = "Actual costs vary based on usage. This is a conservative estimate."
  }
}

# ============================================================================
# VALIDATION AND READINESS
# ============================================================================

output "dr_readiness_checklist" {
  description = "Checklist for DR activation readiness"
  value = {
    configuration_complete = (
      var.enable_cloud_run_dr ||
      var.enable_firestore_dr ||
      var.enable_cloud_sql_dr ||
      var.enable_storage_dr
    )
    monitoring_enabled      = var.enable_dr_monitoring
    notification_configured = length(var.dr_notification_channels) > 0
    budget_alerts_enabled   = var.enable_cost_alerts
    rto_rpo_defined         = var.rto_minutes > 0 && var.rpo_minutes > 0
    regions_configured      = var.primary_region != "" && var.secondary_region != ""
    ready_for_production = (
      var.environment == "production" &&
      length(var.dr_notification_channels) > 0 &&
      var.enable_dr_monitoring
    )
  }
}

output "next_steps" {
  description = "Recommended next steps for DR activation"
  value = var.enable_cloud_run_dr || var.enable_firestore_dr || var.enable_cloud_sql_dr || var.enable_storage_dr ? [
    "1. Review DR monitoring dashboard for all components",
    "2. Test failover procedures in non-production environment",
    "3. Schedule quarterly DR drill with team",
    "4. Document actual RTO/RPO metrics",
    "5. Review and optimize costs monthly"
    ] : [
    "1. DR is NOT ACTIVATED (configurations are preparatory only)",
    "2. Review cost estimates before enabling in production",
    "3. Ensure notification channels are configured",
    "4. Schedule team training on DR procedures",
    "5. When ready: set enable_*_dr = true in production terraform.tfvars"
  ]
}

# ============================================================================
# ACTIVATION DOCUMENTATION
# ============================================================================

output "documentation_links" {
  description = "Links to DR documentation and procedures"
  value = {
    readme              = "infra/modules/disaster-recovery/README.md"
    activation_guide    = "docs/deployment/dr-activation-procedures.md"
    runbook             = "docs/deployment/disaster-recovery-runbook.md"
    cost_analysis       = "docs/deployment/dr-cost-analysis.md"
    rollback_procedures = "docs/deployment/dr-rollback-procedures.md"
  }
}
