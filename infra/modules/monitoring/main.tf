# Monitoring Module - Uptime Checks & Alerts
# Cost: $0.30/check/month (primeros 3 uptime checks FREE)

terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.0"
    }
  }
}

# ================================================================================
# UPTIME CHECKS
# ================================================================================

# Uptime Check - API Health Endpoint
resource "google_monitoring_uptime_check_config" "api_health" {
  display_name = "${var.project_name}-${var.environment}-api-uptime"
  timeout      = "10s"
  period       = "60s" # Check every 1 minute

  http_check {
    path           = "/health"
    port           = "443"
    use_ssl        = true
    validate_ssl   = true
    request_method = "GET"

    accepted_response_status_codes {
      status_class = "STATUS_CLASS_2XX"
    }
  }

  monitored_resource {
    type = "uptime_url"
    labels = {
      project_id = var.project_id
      host       = var.domain  # Changed from "api.${var.domain}" - Load Balancer routes /health to API backend
    }
  }

  # Check from multiple regions for redundancy
  selected_regions = [
    "USA",
    "EUROPE",
    "SOUTH_AMERICA"
  ]

  # Alert policy attachment
  checker_type = "STATIC_IP_CHECKERS"
}

# Uptime Check - Frontend Homepage
resource "google_monitoring_uptime_check_config" "web_homepage" {
  display_name = "${var.project_name}-${var.environment}-web-uptime"
  timeout      = "10s"
  period       = "300s" # Check every 5 minutes (less critical than API)

  http_check {
    path           = "/"
    port           = "443"
    use_ssl        = true
    validate_ssl   = true
    request_method = "GET"

    accepted_response_status_codes {
      status_class = "STATUS_CLASS_2XX"
    }
  }

  monitored_resource {
    type = "uptime_url"
    labels = {
      project_id = var.project_id
      host       = var.domain
    }
  }

  selected_regions = [
    "USA",
    "EUROPE"
  ]

  checker_type = "STATIC_IP_CHECKERS"
}

# ================================================================================
# NOTIFICATION CHANNELS
# ================================================================================

# Email Notification Channel
resource "google_monitoring_notification_channel" "email_alerts" {
  display_name = "${var.project_name}-${var.environment}-email-alerts"
  type         = "email"

  labels = {
    email_address = var.alert_email
  }

  enabled = true
}

# SMS Notification Channel (optional - requires verification)
resource "google_monitoring_notification_channel" "sms_critical" {
  count = var.enable_sms_alerts ? 1 : 0

  display_name = "${var.project_name}-${var.environment}-sms-critical"
  type         = "sms"

  labels = {
    number = var.alert_phone_number
  }

  enabled = true
}

# ================================================================================
# ALERT POLICIES
# ================================================================================

# Alert Policy - API Downtime
resource "google_monitoring_alert_policy" "api_downtime" {
  display_name = "${var.project_name}-${var.environment}-api-downtime"
  combiner     = "OR"

  conditions {
    display_name = "API Health Check Failure"

    condition_threshold {
      filter          = "resource.type=\"uptime_url\" AND metric.type=\"monitoring.googleapis.com/uptime_check/check_passed\" AND resource.labels.host=\"${var.domain}\""
      duration        = "60s" # Alert after 1 minute of failures
      comparison      = "COMPARISON_LT"
      threshold_value = 1

      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_FRACTION_TRUE"
      }
    }
  }

  notification_channels = concat(
    [google_monitoring_notification_channel.email_alerts.id],
    var.enable_sms_alerts ? [google_monitoring_notification_channel.sms_critical[0].id] : []
  )

  alert_strategy {
    auto_close = "1800s" # Auto-close after 30 minutes of recovery
  }

  documentation {
    content   = <<-EOT
      ## API Health Check Failure

      **Service**: ${var.project_name} API (${var.environment})
      **Endpoint**: https://${var.domain}/health (Load Balancer routes to API backend)

      ### Immediate Actions:
      1. Check API logs: `gcloud logging read "resource.labels.service_name=adyela-api-${var.environment}" --limit=50`
      2. Check Cloud Run status: `gcloud run services describe adyela-api-${var.environment} --region=us-central1`
      3. Verify Load Balancer health: GCP Console → Network Services → Load Balancing

      ### Escalation:
      - If downtime >5 minutes: Page on-call engineer
      - If downtime >15 minutes: Notify leadership

      ### Recovery:
      - Check recent deployments: `gcloud run revisions list --service=adyela-api-${var.environment}`
      - Rollback if needed: `gcloud run services update-traffic adyela-api-${var.environment} --to-revisions=PREVIOUS_REVISION=100`
    EOT
    mime_type = "text/markdown"
  }

  enabled = true
}

# Alert Policy - High Error Rate
resource "google_monitoring_alert_policy" "high_error_rate" {
  display_name = "${var.project_name}-${var.environment}-high-error-rate"
  combiner     = "OR"

  conditions {
    display_name = "API Error Rate >1%"

    condition_threshold {
      filter = join(" AND ", [
        "resource.type=\"cloud_run_revision\"",
        "resource.labels.service_name=\"adyela-api-${var.environment}\"",
        "metric.type=\"run.googleapis.com/request_count\"",
        "metric.labels.response_code_class!=\"2xx\""
      ])

      duration        = "300s" # 5 minutes
      comparison      = "COMPARISON_GT"
      threshold_value = 0.01 # 1% error rate

      aggregations {
        alignment_period     = "60s"
        per_series_aligner   = "ALIGN_RATE"
        cross_series_reducer = "REDUCE_SUM"
        group_by_fields      = ["resource.service_name"]
      }
    }
  }

  notification_channels = [google_monitoring_notification_channel.email_alerts.id]

  documentation {
    content   = <<-EOT
      ## High API Error Rate Detected

      The API is returning >1% errors in the last 5 minutes.

      ### Check:
      1. Recent error logs: `gcloud logging read "resource.labels.service_name=adyela-api-${var.environment} AND severity>=ERROR" --limit=20`
      2. Error distribution by endpoint
      3. Recent code deployments
    EOT
    mime_type = "text/markdown"
  }

  enabled = true
}

# Alert Policy - High Latency
resource "google_monitoring_alert_policy" "high_latency" {
  display_name = "${var.project_name}-${var.environment}-high-latency"
  combiner     = "OR"

  conditions {
    display_name = "API Latency P95 >1000ms"

    condition_threshold {
      filter = join(" AND ", [
        "resource.type=\"cloud_run_revision\"",
        "resource.labels.service_name=\"adyela-api-${var.environment}\"",
        "metric.type=\"run.googleapis.com/request_latencies\""
      ])

      duration        = "300s" # 5 minutes
      comparison      = "COMPARISON_GT"
      threshold_value = 1000 # 1000ms = 1 second

      aggregations {
        alignment_period     = "60s"
        per_series_aligner   = "ALIGN_DELTA"
        cross_series_reducer = "REDUCE_PERCENTILE_95"
        group_by_fields      = ["resource.service_name"]
      }
    }
  }

  notification_channels = [google_monitoring_notification_channel.email_alerts.id]

  documentation {
    content   = "API latency P95 is above 1 second. Check Cloud Run metrics and database performance."
    mime_type = "text/markdown"
  }

  enabled = true
}

# ================================================================================
# SLO (Service Level Objectives)
# ================================================================================

# SLO - 99.9% Availability
resource "google_monitoring_slo" "api_availability" {
  service      = google_monitoring_custom_service.api_service.service_id
  slo_id       = "api-availability-slo"
  display_name = "API Availability SLO (99.9%)"

  goal                = 0.999 # 99.9%
  rolling_period_days = 30    # 30-day rolling window

  request_based_sli {
    good_total_ratio {
      total_service_filter = join(" AND ", [
        "resource.type=\"cloud_run_revision\"",
        "resource.labels.service_name=\"adyela-api-${var.environment}\"",
        "metric.type=\"run.googleapis.com/request_count\""
      ])

      good_service_filter = join(" AND ", [
        "resource.type=\"cloud_run_revision\"",
        "resource.labels.service_name=\"adyela-api-${var.environment}\"",
        "metric.type=\"run.googleapis.com/request_count\"",
        "metric.labels.response_code_class=\"2xx\""
      ])
    }
  }
}

# Custom Service Definition
resource "google_monitoring_custom_service" "api_service" {
  service_id   = "adyela-api-${var.environment}"
  display_name = "Adyela API (${var.environment})"

  telemetry {
    resource_name = "//run.googleapis.com/projects/${var.project_id}/locations/us-central1/services/adyela-api-${var.environment}"
  }
}

# ================================================================================
# DASHBOARD
# ================================================================================

resource "google_monitoring_dashboard" "main_dashboard" {
  dashboard_json = jsonencode({
    displayName = "${var.project_name} ${var.environment} - Main Dashboard"

    mosaicLayout = {
      columns = 12

      tiles = [
        # Tile 1: API Request Rate
        {
          width  = 6
          height = 4
          widget = {
            title = "API Request Rate"
            xyChart = {
              dataSets = [{
                timeSeriesQuery = {
                  timeSeriesFilter = {
                    filter = "resource.type=\"cloud_run_revision\" AND resource.labels.service_name=\"adyela-api-${var.environment}\" AND metric.type=\"run.googleapis.com/request_count\""
                    aggregation = {
                      alignmentPeriod  = "60s"
                      perSeriesAligner = "ALIGN_RATE"
                    }
                  }
                }
              }]
            }
          }
        },

        # Tile 2: Error Rate
        {
          width  = 6
          height = 4
          xPos   = 6
          widget = {
            title = "Error Rate (%)"
            xyChart = {
              dataSets = [{
                timeSeriesQuery = {
                  timeSeriesFilter = {
                    filter = "resource.type=\"cloud_run_revision\" AND resource.labels.service_name=\"adyela-api-${var.environment}\" AND metric.type=\"run.googleapis.com/request_count\" AND metric.labels.response_code_class!=\"2xx\""
                    aggregation = {
                      alignmentPeriod    = "60s"
                      perSeriesAligner   = "ALIGN_RATE"
                      crossSeriesReducer = "REDUCE_SUM"
                    }
                  }
                }
              }]
            }
          }
        },

        # Tile 3: Latency Percentiles
        {
          width  = 12
          height = 4
          yPos   = 4
          widget = {
            title = "Request Latency (P50, P95, P99)"
            xyChart = {
              dataSets = [
                {
                  timeSeriesQuery = {
                    timeSeriesFilter = {
                      filter = "resource.type=\"cloud_run_revision\" AND resource.labels.service_name=\"adyela-api-${var.environment}\" AND metric.type=\"run.googleapis.com/request_latencies\""
                      aggregation = {
                        alignmentPeriod    = "60s"
                        perSeriesAligner   = "ALIGN_DELTA"
                        crossSeriesReducer = "REDUCE_PERCENTILE_50"
                      }
                    }
                  }
                  plotType   = "LINE"
                  targetAxis = "Y1"
                },
                {
                  timeSeriesQuery = {
                    timeSeriesFilter = {
                      filter = "resource.type=\"cloud_run_revision\" AND resource.labels.service_name=\"adyela-api-${var.environment}\" AND metric.type=\"run.googleapis.com/request_latencies\""
                      aggregation = {
                        alignmentPeriod    = "60s"
                        perSeriesAligner   = "ALIGN_DELTA"
                        crossSeriesReducer = "REDUCE_PERCENTILE_95"
                      }
                    }
                  }
                  plotType   = "LINE"
                  targetAxis = "Y1"
                },
                {
                  timeSeriesQuery = {
                    timeSeriesFilter = {
                      filter = "resource.type=\"cloud_run_revision\" AND resource.labels.service_name=\"adyela-api-${var.environment}\" AND metric.type=\"run.googleapis.com/request_latencies\""
                      aggregation = {
                        alignmentPeriod    = "60s"
                        perSeriesAligner   = "ALIGN_DELTA"
                        crossSeriesReducer = "REDUCE_PERCENTILE_99"
                      }
                    }
                  }
                  plotType   = "LINE"
                  targetAxis = "Y1"
                }
              ]
            }
          }
        }
      ]
    }
  })
}
