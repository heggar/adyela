# Multi-Region Cloud Run Deployment for Disaster Recovery
# CONFIGURATION ONLY - FOR PRODUCTION ACTIVATION ONLY
#
# This module deploys Cloud Run services in a secondary region (us-east1) for
# disaster recovery failover. Services run in cold standby mode (0 min instances)
# to minimize costs until failover is needed.
#
# ACTIVATION: Only enable in production when SLA commitments require DR
# COST IMPACT: $80-120/month when activated (cold standby)
#              $200-300/month for warm standby (min_instances > 0)

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
# SECONDARY REGION CLOUD RUN SERVICES (STANDBY)
# ============================================================================

# Deploy each service to secondary region for DR failover
resource "google_cloud_run_service" "secondary" {
  for_each = { for svc in var.services : svc.name => svc }

  project  = var.project_id
  name     = "${each.value.name}-dr" # Append -dr to distinguish from primary
  location = var.secondary_region

  template {
    metadata {
      annotations = {
        # Autoscaling configuration
        "autoscaling.knative.dev/minScale" = tostring(var.min_secondary_instances)
        "autoscaling.knative.dev/maxScale" = tostring(lookup(each.value, "max_instances", 10))

        # VPC connector for private networking (if configured)
        "run.googleapis.com/vpc-access-connector" = var.vpc_connector_name != null ? var.vpc_connector_name : null
        "run.googleapis.com/vpc-access-egress"    = var.vpc_connector_name != null ? "all-traffic" : null

        # Execution environment
        "run.googleapis.com/execution-environment" = "gen2"
      }

      labels = merge(
        var.labels,
        {
          environment       = var.environment
          disaster_recovery = "enabled"
          dr_mode           = var.min_secondary_instances == 0 ? "cold-standby" : "warm-standby"
          dr_region         = var.secondary_region
        }
      )
    }

    spec {
      # Container configuration
      containers {
        image = each.value.image

        # Resource limits
        resources {
          limits = {
            cpu    = lookup(each.value, "cpu_limit", "1")
            memory = lookup(each.value, "memory_limit", "512Mi")
          }
        }

        # Environment variables
        dynamic "env" {
          for_each = lookup(each.value, "env_vars", {})
          content {
            name  = env.key
            value = env.value
          }
        }

        # Secrets from Secret Manager
        dynamic "env" {
          for_each = lookup(each.value, "secrets", {})
          content {
            name = env.key
            value_from {
              secret_key_ref {
                name = env.value
                key  = "latest"
              }
            }
          }
        }

        # Health check endpoint
        liveness_probe {
          http_get {
            path = var.health_check_path
          }
          initial_delay_seconds = 10
          timeout_seconds       = 5
          period_seconds        = 10
          failure_threshold     = 3
        }
      }

      # Service account
      service_account_name = var.service_account_email

      # Request timeout
      timeout_seconds = 300

      # Concurrency
      container_concurrency = 80
    }
  }

  traffic {
    # In standby mode, traffic is 0% (controlled by load balancer)
    percent         = 100
    latest_revision = true
  }

  # Lifecycle
  lifecycle {
    ignore_changes = [
      template[0].metadata[0].annotations["run.googleapis.com/client-name"],
      template[0].metadata[0].annotations["run.googleapis.com/client-version"],
    ]
  }

  depends_on = [
    google_project_service.cloud_run_api
  ]
}

# Enable Cloud Run API
resource "google_project_service" "cloud_run_api" {
  project = var.project_id
  service = "run.googleapis.com"

  disable_on_destroy = false
}

# ============================================================================
# IAM POLICY - ALLOW INVOKER ACCESS
# ============================================================================

# Allow authenticated users to invoke secondary services
resource "google_cloud_run_service_iam_member" "invoker" {
  for_each = { for svc in var.services : svc.name => svc }

  project  = var.project_id
  location = var.secondary_region
  service  = google_cloud_run_service.secondary[each.key].name
  role     = "roles/run.invoker"
  member   = var.allow_public_access ? "allUsers" : "serviceAccount:${var.service_account_email}"
}

# ============================================================================
# BACKEND SERVICE FOR LOAD BALANCER FAILOVER
# ============================================================================

# Create Network Endpoint Group (NEG) for each Cloud Run service
resource "google_compute_region_network_endpoint_group" "secondary_neg" {
  for_each = { for svc in var.services : svc.name => svc }

  project               = var.project_id
  name                  = "${each.value.name}-dr-neg"
  region                = var.secondary_region
  network_endpoint_type = "SERVERLESS"

  cloud_run {
    service = google_cloud_run_service.secondary[each.key].name
  }
}

# Backend service for load balancer (controlled from main LB module)
resource "google_compute_backend_service" "secondary_backend" {
  for_each = var.create_backend_service ? { for svc in var.services : svc.name => svc } : {}

  project = var.project_id
  name    = "${each.value.name}-dr-backend"

  # Protocol
  protocol    = "HTTPS"
  port_name   = "http"
  timeout_sec = 30

  # Backend configuration
  backend {
    group = google_compute_region_network_endpoint_group.secondary_neg[each.key].id

    balancing_mode  = "UTILIZATION"
    capacity_scaler = 1.0 # Full capacity available for failover
  }

  # Health check
  health_checks = [google_compute_health_check.secondary_health[each.key].id]

  # Session affinity
  session_affinity        = "CLIENT_IP"
  affinity_cookie_ttl_sec = 3600

  # Connection draining timeout
  connection_draining_timeout_sec = 300

  # CDN configuration (if enabled)
  dynamic "cdn_policy" {
    for_each = var.enable_cdn ? [1] : []
    content {
      cache_mode  = "CACHE_ALL_STATIC"
      default_ttl = 3600
      max_ttl     = 86400
      client_ttl  = 3600
    }
  }

  # Security policy (Cloud Armor)
  security_policy = var.security_policy_id

  # Labels
  custom_response_headers = [
    "X-DR-Region: ${var.secondary_region}",
    "X-DR-Mode: ${var.min_secondary_instances == 0 ? "cold-standby" : "warm-standby"}"
  ]

  lifecycle {
    create_before_destroy = true
  }
}

# ============================================================================
# HEALTH CHECK FOR FAILOVER
# ============================================================================

resource "google_compute_health_check" "secondary_health" {
  for_each = { for svc in var.services : svc.name => svc }

  project = var.project_id
  name    = "${each.value.name}-dr-health"

  # Check interval
  check_interval_sec  = 10
  timeout_sec         = 5
  healthy_threshold   = 2
  unhealthy_threshold = var.failover_threshold # 3 consecutive failures

  # HTTP health check
  https_health_check {
    request_path = var.health_check_path
    port         = 443
  }

  log_config {
    enable = true
  }
}

# ============================================================================
# MONITORING ALERTS FOR SECONDARY REGION
# ============================================================================

# Alert when secondary service is unavailable (DR capability compromised)
resource "google_monitoring_alert_policy" "secondary_service_down" {
  for_each = var.enable_monitoring ? { for svc in var.services : svc.name => svc } : {}

  project      = var.project_id
  display_name = "[DR] Secondary Service Down - ${each.value.name}"

  conditions {
    display_name = "Secondary region ${var.secondary_region} service unavailable"

    condition_threshold {
      filter = "resource.type=\"cloud_run_revision\" AND resource.labels.service_name=\"${each.value.name}-dr\" AND resource.labels.location=\"${var.secondary_region}\" AND metric.type=\"run.googleapis.com/request_count\""

      duration        = "180s" # 3 minutes
      comparison      = "COMPARISON_LT"
      threshold_value = 0.01 # Effectively no requests (cold standby is OK)

      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_RATE"
      }
    }
  }

  notification_channels = var.notification_channels

  alert_strategy {
    auto_close = "3600s"
  }

  documentation {
    content   = <<-EOT
      **DISASTER RECOVERY ALERT**

      Secondary Cloud Run service '${each.value.name}-dr' in ${var.secondary_region} is down.

      **Impact**: DR failover capability compromised
      **RTO**: Cannot meet <15min target if primary region fails

      **Actions**:
      1. Check service status: gcloud run services describe ${each.value.name}-dr --region=${var.secondary_region}
      2. Check last deployment: gcloud run revisions list --service=${each.value.name}-dr --region=${var.secondary_region}
      3. Review logs: gcloud logging read "resource.type=cloud_run_revision AND resource.labels.service_name=${each.value.name}-dr"
      4. Test health endpoint: curl https://[SERVICE_URL]${var.health_check_path}

      **Escalation**: IMMEDIATE - DR capability is critical for SLA compliance
    EOT
    mime_type = "text/markdown"
  }
}

# ============================================================================
# LABELS FOR COST TRACKING
# ============================================================================

locals {
  common_labels = merge(
    var.labels,
    {
      disaster_recovery = "enabled"
      dr_component      = "cloud-run-failover"
      dr_region         = var.secondary_region
      cost_center       = "infrastructure-dr"
    }
  )
}
