# Cross-Region Storage Disaster Recovery - Outputs
# Information about DR storage buckets for monitoring and validation

# ============================================================================
# BUCKET INFORMATION
# ============================================================================

output "bucket_names" {
  description = "Names of DR storage buckets"
  value       = [for bucket in google_storage_bucket.dr_bucket : bucket.name]
}

output "bucket_urls" {
  description = "GCS URLs of DR storage buckets"
  value = {
    for name, bucket in google_storage_bucket.dr_bucket : name => bucket.url
  }
}

output "bucket_self_links" {
  description = "Self-links of DR storage buckets"
  value = {
    for name, bucket in google_storage_bucket.dr_bucket : name => bucket.self_link
  }
}

# ============================================================================
# REPLICATION CONFIGURATION
# ============================================================================

output "replication_config" {
  description = "Replication configuration for DR buckets"
  value = {
    type              = var.replication_type
    location          = var.dr_location
    turbo_replication = var.enable_turbo_replication
    regions           = var.enable_turbo_replication ? var.turbo_replication_regions : []
  }
}

output "dr_location" {
  description = "DR location for storage buckets"
  value       = var.dr_location
}

output "turbo_replication_enabled" {
  description = "Whether turbo replication is enabled"
  value       = var.enable_turbo_replication
}

# ============================================================================
# BUCKET DETAILS
# ============================================================================

output "bucket_details" {
  description = "Detailed information about each DR bucket"
  value = {
    for name, bucket in google_storage_bucket.dr_bucket : name => {
      name          = bucket.name
      location      = bucket.location
      storage_class = bucket.storage_class
      versioning    = bucket.versioning[0].enabled
      url           = bucket.url
      self_link     = bucket.self_link
      labels        = bucket.labels
    }
  }
}

# ============================================================================
# SECURITY CONFIGURATION
# ============================================================================

output "encryption_enabled" {
  description = "Whether CMEK encryption is enabled"
  value       = var.kms_key_name != null
}

output "kms_key_used" {
  description = "KMS key used for encryption (if enabled)"
  value       = var.kms_key_name
  sensitive   = false
}

output "access_logging_enabled" {
  description = "Whether access logging is enabled"
  value       = var.access_logging_bucket != null
}

# ============================================================================
# LIFECYCLE CONFIGURATION
# ============================================================================

output "version_retention_days" {
  description = "Number of days old versions are retained"
  value       = var.version_retention_days
}

output "lifecycle_rules_summary" {
  description = "Summary of lifecycle rules applied to buckets"
  value = {
    nearline_transition_days = 30
    coldline_transition_days = 90
    version_retention_days   = var.version_retention_days
    keep_latest_versions     = 3
  }
}

# ============================================================================
# MONITORING STATUS
# ============================================================================

output "monitoring_enabled" {
  description = "Whether monitoring alerts are enabled"
  value       = var.enable_monitoring
}

output "quota_alerts_configured" {
  description = "Number of quota alerts configured"
  value       = var.enable_monitoring ? length([for bucket in var.buckets : bucket if lookup(bucket, "quota_gb", 0) > 0]) : 0
}

# ============================================================================
# COST ESTIMATION
# ============================================================================

output "estimated_monthly_cost_usd" {
  description = "Estimated monthly cost for cross-region storage (approximate)"
  value = {
    storage_base        = var.replication_type == "dual-region" ? 40 : 60
    turbo_replication   = var.enable_turbo_replication ? 30 : 0
    versioning_overhead = 20 # Estimate for version storage
    egress_estimate     = 10 # Cross-region egress
    kms_operations      = var.kms_key_name != null ? 5 : 0
    total_min           = var.replication_type == "dual-region" ? (var.enable_turbo_replication ? 105 : 75) : 95
    total_max           = var.replication_type == "dual-region" ? (var.enable_turbo_replication ? 140 : 110) : 150
    mode                = var.replication_type == "dual-region" ? (var.enable_turbo_replication ? "Dual-Region + Turbo" : "Dual-Region") : "Multi-Region"
    note                = "Actual costs vary based on stored data size and access patterns. Add ~$0.026/GB for STANDARD storage."
  }
}

# ============================================================================
# DR READINESS
# ============================================================================

output "dr_readiness" {
  description = "DR readiness status for cross-region storage"
  value = {
    buckets_configured = length(var.buckets)
    buckets_deployed   = length(google_storage_bucket.dr_bucket)
    versioning_enabled = alltrue([for bucket in var.buckets : lookup(bucket, "versioning", true)])
    monitoring_enabled = var.enable_monitoring
    encryption_enabled = var.kms_key_name != null
    turbo_replication  = var.enable_turbo_replication
    replication_type   = var.replication_type
    dr_location        = var.dr_location
    ready_for_production = (
      length(google_storage_bucket.dr_bucket) > 0 &&
      var.prevent_bucket_destroy &&
      !var.allow_force_destroy
    )
  }
}

# ============================================================================
# VALIDATION CHECKLIST
# ============================================================================

output "validation_checklist" {
  description = "Pre-activation validation checklist"
  value = [
    "✅ ${length(var.buckets)} DR buckets configured",
    "✅ Replication: ${var.replication_type} (${var.dr_location})",
    var.enable_turbo_replication ? "✅ Turbo replication enabled (RPO <15min)" : "💰 Cold replication (RPO ~1 hour)",
    alltrue([for bucket in var.buckets : lookup(bucket, "versioning", true)]) ? "✅ Versioning enabled on all buckets" : "⚠️ Some buckets have versioning disabled",
    var.kms_key_name != null ? "✅ CMEK encryption configured" : "⚠️ Using Google-managed encryption (consider CMEK for compliance)",
    var.access_logging_bucket != null ? "✅ Access logging enabled" : "⚠️ Access logging not configured",
    var.enable_monitoring ? "✅ Monitoring alerts configured" : "⚠️ Monitoring not enabled",
    length(var.notification_channels) > 0 ? "✅ Notification channels configured" : "⚠️ No notification channels",
    var.prevent_bucket_destroy ? "✅ Bucket destruction prevention enabled" : "⚠️ Buckets can be destroyed",
    !var.allow_force_destroy ? "✅ Force destroy disabled" : "⚠️ Force destroy enabled (unsafe for production)"
  ]
}

# ============================================================================
# USAGE COMMANDS
# ============================================================================

output "usage_commands" {
  description = "Useful gsutil commands for DR buckets"
  value = {
    list_all_buckets  = "gsutil ls -L | grep ${var.dr_location}"
    check_replication = "gsutil ls -L gs://BUCKET_NAME | grep -i location"
    view_lifecycle    = "gsutil lifecycle get gs://BUCKET_NAME"
    list_versions     = "gsutil ls -a gs://BUCKET_NAME"
    check_size        = "gsutil du -sh gs://BUCKET_NAME"
    sync_to_bucket    = "gsutil -m rsync -r -d LOCAL_DIR gs://BUCKET_NAME"
    restore_version   = "gsutil cp gs://BUCKET_NAME/object#VERSION gs://BUCKET_NAME/object"
  }
}

# ============================================================================
# ACTIVATION INSTRUCTIONS
# ============================================================================

output "activation_instructions" {
  description = "Instructions for activating cross-region storage DR in production"
  value       = <<-EOT
    # Cross-Region Storage Disaster Recovery - Activation Instructions

    ## Current Configuration:
    - Buckets: ${length(var.buckets)} configured
    - Replication: ${var.replication_type} (${var.dr_location})
    - Turbo Replication: ${var.enable_turbo_replication ? "Enabled (RPO <15min)" : "Disabled (RPO ~1 hour)"}
    - Versioning: ${alltrue([for bucket in var.buckets : lookup(bucket, "versioning", true)]) ? "Enabled on all buckets" : "Enabled on some buckets"}

    ## To Activate in Production:
    1. Set enable_storage_dr = true in production terraform.tfvars
    2. Configure storage_buckets_for_dr with production bucket list
    3. Set dr_location based on compliance requirements:
       - US: Multi-region across all US regions
       - NAM4: Dual-region (Iowa + South Carolina)
    4. Enable turbo_replication if RPO <15min is required (additional cost)
    5. Configure KMS key for CMEK encryption (recommended for HIPAA)
    6. Set up access logging bucket for audit trail
    7. Review estimated costs ($${var.replication_type == "dual-region" ? (var.enable_turbo_replication ? "105-140" : "75-110") : "95-150"}/month + storage costs)
    8. Run: terraform plan -var-file=production.tfvars
    9. Verify bucket configurations and replication settings
    10. Run: terraform apply -var-file=production.tfvars

    ## Post-Activation Validation:
    ${join("\n    ", [for bucket in var.buckets : "gsutil ls -L gs://${bucket.name} | grep -E 'Location|Versioning'"])}

    ## Monitoring:
    - View bucket metrics: Cloud Console > Storage > Browser
    - Check replication status: gsutil ls -L gs://BUCKET_NAME | grep Turbo
    - Monitor costs: Cloud Console > Billing > Reports (filter by 'disaster_recovery' label)

    ## Cost Optimization Tips:
    - Dual-region (NAM4): Lower cost, specific region pair
    - Multi-region (US): Higher cost, broader distribution
    - Turbo replication: +$0.04/GB, use only if strict RPO required
    - Lifecycle rules: Automatically transition to NEARLINE (30d) and COLDLINE (90d)

    ## Recovery Procedures:
    - Restore deleted object: gsutil cp gs://BUCKET/object#VERSION gs://BUCKET/object
    - List all versions: gsutil ls -a gs://BUCKET/path/
    - Cross-region failover: Automatic (no action needed, geo-redundant)

    IMPORTANT: This is a PRODUCTION-ONLY configuration. Do NOT enable in staging.
  EOT
}
