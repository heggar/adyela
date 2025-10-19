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
      host       = var.domain # Changed from "api.${var.domain}" - Load Balancer routes /health to API backend
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
# LOG SINKS - Centralized Logging
# ================================================================================

# BigQuery Dataset for Log Analysis
resource "google_bigquery_dataset" "log_dataset" {
  count = var.enable_log_sinks ? 1 : 0

  dataset_id  = "${var.project_name}_${var.environment}_logs"
  project     = var.project_id
  location    = var.region
  description = "Centralized logs for ${var.project_name} ${var.environment} environment"

  default_table_expiration_ms = 7776000000 # 90 days

  labels = {
    environment = var.environment
    purpose     = "logging"
  }
}

# Log Sink - Application Logs
resource "google_logging_project_sink" "application_logs" {
  count = var.enable_log_sinks ? 1 : 0

  name        = "${var.project_name}-${var.environment}-app-logs"
  description = "Application logs from Cloud Run services"
  destination = "bigquery.googleapis.com/projects/${var.project_id}/datasets/${google_bigquery_dataset.log_dataset[0].dataset_id}"

  filter = <<-EOT
    resource.type="cloud_run_revision"
    (resource.labels.service_name=~"adyela-.*-${var.environment}"
    OR resource.labels.service_name=~"${var.project_name}-.*-${var.environment}")
    severity >= DEFAULT
  EOT

  unique_writer_identity = true

  bigquery_options {
    use_partitioned_tables = true
  }
}

# Log Sink - Error Logs
resource "google_logging_project_sink" "error_logs" {
  count = var.enable_log_sinks ? 1 : 0

  name        = "${var.project_name}-${var.environment}-error-logs"
  description = "Error and critical logs from all services"
  destination = "bigquery.googleapis.com/projects/${var.project_id}/datasets/${google_bigquery_dataset.log_dataset[0].dataset_id}"

  filter = <<-EOT
    severity >= ERROR
    resource.type="cloud_run_revision"
  EOT

  unique_writer_identity = true

  bigquery_options {
    use_partitioned_tables = true
  }
}

# Log Sink - Security & Audit Logs (HIPAA Requirement)
resource "google_logging_project_sink" "audit_logs" {
  count = var.enable_log_sinks ? 1 : 0

  name        = "${var.project_name}-${var.environment}-audit-logs"
  description = "HIPAA-compliant audit logs for PHI access tracking"
  destination = "bigquery.googleapis.com/projects/${var.project_id}/datasets/${google_bigquery_dataset.log_dataset[0].dataset_id}"

  filter = <<-EOT
    protoPayload.@type="type.googleapis.com/google.cloud.audit.AuditLog"
    OR jsonPayload.labels.hipaa_audit="true"
    OR jsonPayload.phi_access=true
  EOT

  unique_writer_identity = true

  bigquery_options {
    use_partitioned_tables = true
  }
}

# Grant BigQuery Data Editor role to log sinks
resource "google_bigquery_dataset_iam_member" "app_logs_writer" {
  count = var.enable_log_sinks ? 1 : 0

  dataset_id = google_bigquery_dataset.log_dataset[0].dataset_id
  role       = "roles/bigquery.dataEditor"
  member     = google_logging_project_sink.application_logs[0].writer_identity
}

resource "google_bigquery_dataset_iam_member" "error_logs_writer" {
  count = var.enable_log_sinks ? 1 : 0

  dataset_id = google_bigquery_dataset.log_dataset[0].dataset_id
  role       = "roles/bigquery.dataEditor"
  member     = google_logging_project_sink.error_logs[0].writer_identity
}

resource "google_bigquery_dataset_iam_member" "audit_logs_writer" {
  count = var.enable_log_sinks ? 1 : 0

  dataset_id = google_bigquery_dataset.log_dataset[0].dataset_id
  role       = "roles/bigquery.dataEditor"
  member     = google_logging_project_sink.audit_logs[0].writer_identity
}

# ================================================================================
# ERROR REPORTING
# ================================================================================

# Error Reporting is enabled by default for Cloud Run
# No explicit resources needed, but we can create notification channels

resource "google_monitoring_alert_policy" "error_reporting_alert" {
  display_name = "${var.project_name}-${var.environment}-error-reporting"
  combiner     = "OR"

  conditions {
    display_name = "New Error Type Detected"

    condition_threshold {
      filter = join(" AND ", [
        "resource.type=\"cloud_run_revision\"",
        "resource.labels.service_name=~\"adyela-.*-${var.environment}\"",
        "metric.type=\"logging.googleapis.com/user/error_count\""
      ])

      duration        = "60s"
      comparison      = "COMPARISON_GT"
      threshold_value = 0

      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_RATE"
      }
    }
  }

  notification_channels = [google_monitoring_notification_channel.email_alerts.id]

  documentation {
    content   = "New error type detected in Error Reporting. Check https://console.cloud.google.com/errors"
    mime_type = "text/markdown"
  }

  enabled = var.enable_error_reporting_alerts
}

# ================================================================================
# CLOUD TRACE - Distributed Tracing
# ================================================================================

# Cloud Trace is automatically enabled for Cloud Run
# Configure sampling and create custom spans in application code

# Alert on high trace latency
resource "google_monitoring_alert_policy" "trace_latency" {
  count = var.enable_trace_alerts ? 1 : 0

  display_name = "${var.project_name}-${var.environment}-trace-latency"
  combiner     = "OR"

  conditions {
    display_name = "Distributed Trace Latency >2s"

    condition_threshold {
      filter = join(" AND ", [
        "resource.type=\"cloud_run_revision\"",
        "metric.type=\"cloudtrace.googleapis.com/span/latencies\""
      ])

      duration        = "300s"
      comparison      = "COMPARISON_GT"
      threshold_value = 2000 # 2 seconds

      aggregations {
        alignment_period     = "60s"
        per_series_aligner   = "ALIGN_DELTA"
        cross_series_reducer = "REDUCE_PERCENTILE_95"
      }
    }
  }

  notification_channels = [google_monitoring_notification_channel.email_alerts.id]

  documentation {
    content   = "Distributed trace latency exceeds 2 seconds. Check trace details in Cloud Console."
    mime_type = "text/markdown"
  }

  enabled = true
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

# ================================================================================
# ADVANCED SLOs - Error Budgets & Burn Rate Alerts
# ================================================================================

# SLO - Latency SLI (P95 < target)
resource "google_monitoring_slo" "api_latency" {
  service      = google_monitoring_custom_service.api_service.service_id
  slo_id       = "api-latency-slo"
  display_name = "API Latency SLO (P95 < ${var.latency_slo_target_ms}ms)"

  goal                = var.availability_slo_target # Use same target for simplicity
  rolling_period_days = var.slo_rolling_period_days

  request_based_sli {
    distribution_cut {
      distribution_filter = join(" AND ", [
        "resource.type=\"cloud_run_revision\"",
        "resource.labels.service_name=\"adyela-api-${var.environment}\"",
        "metric.type=\"run.googleapis.com/request_latencies\""
      ])

      range {
        min = 0
        max = var.latency_slo_target_ms
      }
    }
  }
}

# SLO - Error Rate (< target)
resource "google_monitoring_slo" "api_error_rate" {
  service      = google_monitoring_custom_service.api_service.service_id
  slo_id       = "api-error-rate-slo"
  display_name = "API Error Rate SLO (< ${var.error_rate_slo_target * 100}%)"

  goal                = 1 - var.error_rate_slo_target # Invert for SLO
  rolling_period_days = var.slo_rolling_period_days

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
        "(metric.labels.response_code_class=\"2xx\" OR metric.labels.response_code_class=\"3xx\")"
      ])
    }
  }
}

# Alert Policy - SLO Burn Rate (Fast Burn: 2% budget in 1 hour)
resource "google_monitoring_alert_policy" "slo_burn_rate_fast" {
  display_name = "${var.project_name}-${var.environment}-slo-burn-fast"
  combiner     = "OR"

  conditions {
    display_name = "SLO Error Budget Burning Too Fast"

    condition_threshold {
      filter = join(" AND ", [
        "select_slo_burn_rate(\"${google_monitoring_slo.api_availability.id}\", 3600)" # 1 hour
      ])

      duration        = "0s" # Alert immediately
      comparison      = "COMPARISON_GT"
      threshold_value = 10 # 10x burn rate = 2% budget in 1 hour

      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_NEXT_OLDER"
      }
    }
  }

  notification_channels = concat(
    [google_monitoring_notification_channel.email_alerts.id],
    var.enable_sms_alerts ? [google_monitoring_notification_channel.sms_critical[0].id] : []
  )

  alert_strategy {
    auto_close = "7200s" # 2 hours
  }

  documentation {
    content   = <<-EOT
      ## SLO Error Budget Burning Too Fast ⚠️

      **Current Burn Rate**: >10x normal
      **Risk**: May exhaust entire error budget in hours
      **Action Required**: Immediate investigation

      ### Check:
      1. Recent deployments or config changes
      2. Error logs and stack traces
      3. Upstream service health
      4. Database performance

      ### Recovery Steps:
      - Rollback recent changes if identified
      - Scale up resources if capacity issue
      - Enable circuit breakers if cascading failures
    EOT
    mime_type = "text/markdown"
  }

  enabled = true
}

# Alert Policy - SLO Burn Rate (Slow Burn: 10% budget in 24 hours)
resource "google_monitoring_alert_policy" "slo_burn_rate_slow" {
  display_name = "${var.project_name}-${var.environment}-slo-burn-slow"
  combiner     = "OR"

  conditions {
    display_name = "SLO Error Budget Depleting"

    condition_threshold {
      filter = join(" AND ", [
        "select_slo_burn_rate(\"${google_monitoring_slo.api_availability.id}\", 86400)" # 24 hours
      ])

      duration        = "0s"
      comparison      = "COMPARISON_GT"
      threshold_value = 3 # 3x burn rate = 10% budget in 24 hours

      aggregations {
        alignment_period   = "300s"
        per_series_aligner = "ALIGN_NEXT_OLDER"
      }
    }
  }

  notification_channels = [google_monitoring_notification_channel.email_alerts.id]

  alert_strategy {
    auto_close = "86400s" # 24 hours
  }

  documentation {
    content   = "SLO error budget depleting faster than expected. Review error trends and plan remediation."
    mime_type = "text/markdown"
  }

  enabled = true
}

# ================================================================================
# MICROSERVICES DASHBOARDS
# ================================================================================

# Dashboard per Microservice
resource "google_monitoring_dashboard" "microservice_dashboard" {
  for_each = var.enable_microservices_dashboards ? { for ms in var.microservices : ms.name => ms } : {}

  dashboard_json = jsonencode({
    displayName = "${each.value.display_name} - ${var.environment}"

    mosaicLayout = {
      columns = 12

      tiles = concat(
        # Golden Signals: Latency, Traffic, Errors, Saturation
        [
          # Latency (P50, P95, P99)
          {
            width  = 6
            height = 4
            widget = {
              title = "Request Latency"
              xyChart = {
                dataSets = [
                  {
                    timeSeriesQuery = {
                      timeSeriesFilter = {
                        filter = "resource.type=\"cloud_run_revision\" AND resource.labels.service_name=\"${each.value.name}\" AND metric.type=\"run.googleapis.com/request_latencies\""
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
                        filter = "resource.type=\"cloud_run_revision\" AND resource.labels.service_name=\"${each.value.name}\" AND metric.type=\"run.googleapis.com/request_latencies\""
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
                        filter = "resource.type=\"cloud_run_revision\" AND resource.labels.service_name=\"${each.value.name}\" AND metric.type=\"run.googleapis.com/request_latencies\""
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
                yAxis = {
                  label = "Latency (ms)"
                  scale = "LINEAR"
                }
                thresholds = [
                  {
                    value = var.latency_slo_target_ms
                    color = "YELLOW"
                    label = "SLO Target"
                  }
                ]
              }
            }
          },

          # Traffic (Request Rate)
          {
            width  = 6
            height = 4
            xPos   = 6
            widget = {
              title = "Request Rate"
              xyChart = {
                dataSets = [{
                  timeSeriesQuery = {
                    timeSeriesFilter = {
                      filter = "resource.type=\"cloud_run_revision\" AND resource.labels.service_name=\"${each.value.name}\" AND metric.type=\"run.googleapis.com/request_count\""
                      aggregation = {
                        alignmentPeriod  = "60s"
                        perSeriesAligner = "ALIGN_RATE"
                      }
                    }
                  }
                  plotType   = "LINE"
                  targetAxis = "Y1"
                }]
                yAxis = {
                  label = "Requests/second"
                  scale = "LINEAR"
                }
              }
            }
          },

          # Errors (By Response Code)
          {
            width  = 6
            height = 4
            yPos   = 4
            widget = {
              title = "Errors by Response Code"
              xyChart = {
                dataSets = [{
                  timeSeriesQuery = {
                    timeSeriesFilter = {
                      filter = "resource.type=\"cloud_run_revision\" AND resource.labels.service_name=\"${each.value.name}\" AND metric.type=\"run.googleapis.com/request_count\" AND metric.labels.response_code_class!=\"2xx\""
                      aggregation = {
                        alignmentPeriod    = "60s"
                        perSeriesAligner   = "ALIGN_RATE"
                        crossSeriesReducer = "REDUCE_SUM"
                        groupByFields      = ["metric.response_code_class"]
                      }
                    }
                  }
                  plotType   = "STACKED_AREA"
                  targetAxis = "Y1"
                }]
                yAxis = {
                  label = "Errors/second"
                  scale = "LINEAR"
                }
              }
            }
          },

          # Saturation (Container Utilization)
          {
            width  = 6
            height = 4
            xPos   = 6
            yPos   = 4
            widget = {
              title = "Container CPU & Memory"
              xyChart = {
                dataSets = [
                  {
                    timeSeriesQuery = {
                      timeSeriesFilter = {
                        filter = "resource.type=\"cloud_run_revision\" AND resource.labels.service_name=\"${each.value.name}\" AND metric.type=\"run.googleapis.com/container/cpu/utilizations\""
                        aggregation = {
                          alignmentPeriod    = "60s"
                          perSeriesAligner   = "ALIGN_MEAN"
                          crossSeriesReducer = "REDUCE_MEAN"
                        }
                      }
                    }
                    plotType   = "LINE"
                    targetAxis = "Y1"
                  },
                  {
                    timeSeriesQuery = {
                      timeSeriesFilter = {
                        filter = "resource.type=\"cloud_run_revision\" AND resource.labels.service_name=\"${each.value.name}\" AND metric.type=\"run.googleapis.com/container/memory/utilizations\""
                        aggregation = {
                          alignmentPeriod    = "60s"
                          perSeriesAligner   = "ALIGN_MEAN"
                          crossSeriesReducer = "REDUCE_MEAN"
                        }
                      }
                    }
                    plotType   = "LINE"
                    targetAxis = "Y2"
                  }
                ]
                yAxis = {
                  label = "CPU Utilization (%)"
                  scale = "LINEAR"
                }
              }
            }
          }
        ]
        # Removed API-specific tiles for simplified staging monitoring
        # These can be re-enabled in production by setting enable_microservices_dashboards = true
      )
    }
  })
}

# ================================================================================
# SLACK & PAGERDUTY NOTIFICATIONS (Optional)
# ================================================================================

# Slack Notification Channel
resource "google_monitoring_notification_channel" "slack" {
  count = var.enable_slack_notifications && var.slack_webhook_url != "" ? 1 : 0

  display_name = "${var.project_name}-${var.environment}-slack"
  type         = "slack"

  labels = {
    url = var.slack_webhook_url
  }

  enabled = true
}

# PagerDuty Notification Channel
resource "google_monitoring_notification_channel" "pagerduty" {
  count = var.enable_pagerduty_notifications && var.pagerduty_integration_key != "" ? 1 : 0

  display_name = "${var.project_name}-${var.environment}-pagerduty"
  type         = "pagerduty"

  labels = {
    service_key = var.pagerduty_integration_key
  }

  enabled = true
}
