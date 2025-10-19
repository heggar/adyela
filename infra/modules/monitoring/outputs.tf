# ================================================================================
# Uptime Checks Outputs
# ================================================================================

output "api_uptime_check_id" {
  description = "ID of the API uptime check"
  value       = google_monitoring_uptime_check_config.api_health.id
}

output "web_uptime_check_id" {
  description = "ID of the web uptime check"
  value       = google_monitoring_uptime_check_config.web_homepage.id
}

# ================================================================================
# Dashboard Outputs
# ================================================================================

output "dashboard_url" {
  description = "URL to the main monitoring dashboard"
  value       = "https://console.cloud.google.com/monitoring/dashboards/custom/${google_monitoring_dashboard.main_dashboard.id}?project=${var.project_id}"
}

output "dashboard_id" {
  description = "ID of the main dashboard"
  value       = google_monitoring_dashboard.main_dashboard.id
}

output "microservice_dashboard_urls" {
  description = "URLs to microservice dashboards"
  value = {
    for name, dashboard in google_monitoring_dashboard.microservice_dashboard :
    name => "https://console.cloud.google.com/monitoring/dashboards/custom/${dashboard.id}?project=${var.project_id}"
  }
}

# ================================================================================
# SLO Outputs
# ================================================================================

output "slo_availability_name" {
  description = "Name of the availability SLO"
  value       = google_monitoring_slo.api_availability.name
}

output "slo_availability_id" {
  description = "ID of the availability SLO"
  value       = google_monitoring_slo.api_availability.id
}

output "slo_latency_name" {
  description = "Name of the latency SLO"
  value       = google_monitoring_slo.api_latency.name
}

output "slo_latency_id" {
  description = "ID of the latency SLO"
  value       = google_monitoring_slo.api_latency.id
}

output "slo_error_rate_name" {
  description = "Name of the error rate SLO"
  value       = google_monitoring_slo.api_error_rate.name
}

output "slo_error_rate_id" {
  description = "ID of the error rate SLO"
  value       = google_monitoring_slo.api_error_rate.id
}

# ================================================================================
# Alert Policies Outputs
# ================================================================================

output "alert_policy_ids" {
  description = "IDs of all alert policies"
  value = {
    api_downtime       = google_monitoring_alert_policy.api_downtime.id
    high_error_rate    = google_monitoring_alert_policy.high_error_rate.id
    high_latency       = google_monitoring_alert_policy.high_latency.id
    error_reporting    = google_monitoring_alert_policy.error_reporting_alert.id
    slo_burn_rate_fast = google_monitoring_alert_policy.slo_burn_rate_fast.id
    slo_burn_rate_slow = google_monitoring_alert_policy.slo_burn_rate_slow.id
    trace_latency      = var.enable_trace_alerts ? google_monitoring_alert_policy.trace_latency[0].id : null
  }
}

# ================================================================================
# Notification Channels Outputs
# ================================================================================

output "notification_channel_ids" {
  description = "IDs of notification channels"
  value = {
    email     = google_monitoring_notification_channel.email_alerts.id
    sms       = var.enable_sms_alerts ? google_monitoring_notification_channel.sms_critical[0].id : null
    slack     = var.enable_slack_notifications && var.slack_webhook_url != "" ? google_monitoring_notification_channel.slack[0].id : null
    pagerduty = var.enable_pagerduty_notifications && var.pagerduty_integration_key != "" ? google_monitoring_notification_channel.pagerduty[0].id : null
  }
}

# ================================================================================
# Log Sinks Outputs
# ================================================================================

output "log_dataset_id" {
  description = "BigQuery dataset ID for logs"
  value       = var.enable_log_sinks ? google_bigquery_dataset.log_dataset[0].dataset_id : null
}

output "log_dataset_location" {
  description = "Location of the BigQuery dataset"
  value       = var.enable_log_sinks ? google_bigquery_dataset.log_dataset[0].location : null
}

output "log_sink_names" {
  description = "Names of log sinks"
  value = var.enable_log_sinks ? {
    application = google_logging_project_sink.application_logs[0].name
    errors      = google_logging_project_sink.error_logs[0].name
    audit       = google_logging_project_sink.audit_logs[0].name
  } : null
}

output "log_sink_writer_identities" {
  description = "Writer service account identities for log sinks"
  value = var.enable_log_sinks ? {
    application = google_logging_project_sink.application_logs[0].writer_identity
    errors      = google_logging_project_sink.error_logs[0].writer_identity
    audit       = google_logging_project_sink.audit_logs[0].writer_identity
  } : null
  sensitive = true
}

# ================================================================================
# Summary Outputs
# ================================================================================

output "monitoring_summary" {
  description = "Summary of monitoring resources created"
  value = {
    uptime_checks         = 2
    alert_policies        = 6 + (var.enable_trace_alerts ? 1 : 0)
    slos                  = 3
    dashboards            = 1 + length(google_monitoring_dashboard.microservice_dashboard)
    notification_channels = 1 + (var.enable_sms_alerts ? 1 : 0) + (var.enable_slack_notifications && var.slack_webhook_url != "" ? 1 : 0) + (var.enable_pagerduty_notifications && var.pagerduty_integration_key != "" ? 1 : 0)
    log_sinks             = var.enable_log_sinks ? 3 : 0
    log_dataset_created   = var.enable_log_sinks
  }
}

output "observability_urls" {
  description = "Quick access URLs for observability tools"
  value = {
    metrics_explorer = "https://console.cloud.google.com/monitoring/metrics-explorer?project=${var.project_id}"
    logs_explorer    = "https://console.cloud.google.com/logs/query?project=${var.project_id}"
    trace_list       = "https://console.cloud.google.com/traces/list?project=${var.project_id}"
    error_reporting  = "https://console.cloud.google.com/errors?project=${var.project_id}"
    dashboards       = "https://console.cloud.google.com/monitoring/dashboards?project=${var.project_id}"
    uptime_checks    = "https://console.cloud.google.com/monitoring/uptime?project=${var.project_id}"
    slos             = "https://console.cloud.google.com/monitoring/services?project=${var.project_id}"
    alerts           = "https://console.cloud.google.com/monitoring/alerting?project=${var.project_id}"
  }
}
