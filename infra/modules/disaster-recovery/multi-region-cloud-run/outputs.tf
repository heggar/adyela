# Multi-Region Cloud Run Deployment - Outputs
# Information about secondary region services for DR monitoring and validation

# ============================================================================
# SECONDARY SERVICES INFORMATION
# ============================================================================

output "secondary_services" {
  description = "Cloud Run services deployed in secondary region"
  value = {
    for name, service in google_cloud_run_service.secondary : name => {
      name     = service.name
      location = service.location
      url      = service.status[0].url
      image    = service.template[0].spec[0].containers[0].image
    }
  }
}

output "secondary_service_urls" {
  description = "URLs of secondary region Cloud Run services"
  value = {
    for name, service in google_cloud_run_service.secondary : name => service.status[0].url
  }
}

# ============================================================================
# DR STANDBY MODE
# ============================================================================

output "standby_mode" {
  description = "DR standby mode (cold or warm)"
  value       = var.min_secondary_instances == 0 ? "cold-standby" : "warm-standby"
}

output "min_instances_configured" {
  description = "Minimum instances configured for secondary services"
  value       = var.min_secondary_instances
}

# ============================================================================
# BACKEND SERVICE INFORMATION
# ============================================================================

output "backend_services" {
  description = "Backend services for load balancer failover"
  value = var.create_backend_service ? {
    for name, backend in google_compute_backend_service.secondary_backend : name => {
      name      = backend.name
      self_link = backend.self_link
      id        = backend.id
    }
  } : null
}

output "network_endpoint_groups" {
  description = "Network Endpoint Groups (NEG) for secondary services"
  value = {
    for name, neg in google_compute_region_network_endpoint_group.secondary_neg : name => {
      name      = neg.name
      region    = neg.region
      self_link = neg.self_link
    }
  }
}

# ============================================================================
# HEALTH CHECK STATUS
# ============================================================================

output "health_checks" {
  description = "Health check configurations for DR services"
  value = {
    for name, hc in google_compute_health_check.secondary_health : name => {
      name                = hc.name
      check_interval_sec  = hc.check_interval_sec
      timeout_sec         = hc.timeout_sec
      healthy_threshold   = hc.healthy_threshold
      unhealthy_threshold = hc.unhealthy_threshold
      path                = hc.https_health_check[0].request_path
    }
  }
}

output "failover_threshold" {
  description = "Number of consecutive failures before failover"
  value       = var.failover_threshold
}

# ============================================================================
# MONITORING ALERTS
# ============================================================================

output "alert_policies" {
  description = "Monitoring alert policies for secondary services"
  value = var.enable_monitoring ? {
    for name, alert in google_monitoring_alert_policy.secondary_service_down : name => {
      name         = alert.display_name
      id           = alert.id
      service_name = "${name}-dr"
    }
  } : null
}

# ============================================================================
# COST ESTIMATION
# ============================================================================

output "estimated_monthly_cost_usd" {
  description = "Estimated monthly cost for Cloud Run DR (approximate)"
  value = {
    cold_standby_cost = var.min_secondary_instances == 0 ? 20 : 0
    warm_standby_cost = var.min_secondary_instances > 0 ? (80 + (var.min_secondary_instances * 20)) : 0
    total_min         = var.min_secondary_instances == 0 ? 20 : (80 + (var.min_secondary_instances * 20))
    total_max         = var.min_secondary_instances == 0 ? 40 : (120 + (var.min_secondary_instances * 30))
    mode              = var.min_secondary_instances == 0 ? "cold-standby" : "warm-standby"
    note              = "Cold standby: ~$20-40/month. Warm standby: ~$80-120/month + $20-30/instance"
  }
}

# ============================================================================
# DR READINESS
# ============================================================================

output "dr_readiness" {
  description = "DR readiness status for Cloud Run services"
  value = {
    services_configured      = length(var.services)
    services_deployed        = length(google_cloud_run_service.secondary)
    backend_service_ready    = var.create_backend_service
    health_checks_enabled    = true
    monitoring_enabled       = var.enable_monitoring
    notifications_configured = length(var.notification_channels) > 0
    standby_mode             = var.min_secondary_instances == 0 ? "cold-standby" : "warm-standby"
    ready_for_failover       = length(google_cloud_run_service.secondary) > 0 && var.create_backend_service
  }
}

# ============================================================================
# VALIDATION CHECKLIST
# ============================================================================

output "validation_checklist" {
  description = "Pre-activation validation checklist"
  value = [
    "✅ Secondary Cloud Run services deployed in ${var.secondary_region}",
    "✅ Health checks configured with ${var.failover_threshold} failure threshold",
    var.create_backend_service ? "✅ Backend services created for load balancer integration" : "⚠️ Backend services not created",
    var.enable_monitoring ? "✅ Monitoring alerts configured" : "⚠️ Monitoring not enabled",
    length(var.notification_channels) > 0 ? "✅ Notification channels configured" : "⚠️ No notification channels",
    var.min_secondary_instances == 0 ? "💰 Cold standby mode (lowest cost)" : "💰 Warm standby mode (faster failover, higher cost)"
  ]
}

# ============================================================================
# ACTIVATION INSTRUCTIONS
# ============================================================================

output "activation_instructions" {
  description = "Instructions for activating Cloud Run DR in production"
  value       = <<-EOT
    # Cloud Run Disaster Recovery - Activation Instructions

    ## Current Configuration:
    - Region: ${var.secondary_region}
    - Services: ${length(var.services)} configured
    - Standby Mode: ${var.min_secondary_instances == 0 ? "Cold (0 min instances)" : "Warm (${var.min_secondary_instances} min instances)"}

    ## To Activate in Production:
    1. Set enable_cloud_run_dr = true in production terraform.tfvars
    2. Ensure notification_channels are configured
    3. Review and approve estimated costs ($${var.min_secondary_instances == 0 ? "20-40" : "80-120"}/month)
    4. Run: terraform plan -var-file=production.tfvars
    5. Review plan carefully
    6. Run: terraform apply -var-file=production.tfvars
    7. Validate health checks: gcloud compute health-checks list --project=${var.project_id}
    8. Test failover in non-production environment first

    ## Monitoring:
    - View services: gcloud run services list --region=${var.secondary_region} --project=${var.project_id}
    - Check health: gcloud run services describe <service>-dr --region=${var.secondary_region}
    - Monitor alerts: Cloud Console > Monitoring > Alerting

    ## Cost Optimization:
    - Cold standby (min_instances=0): Lowest cost, slower failover (~2-3 min)
    - Warm standby (min_instances=1+): Higher cost, faster failover (<30 sec)

    IMPORTANT: This is a PRODUCTION-ONLY configuration. Do NOT enable in staging.
  EOT
}
