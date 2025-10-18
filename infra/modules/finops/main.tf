# FinOps Module - Budget Alerts and Cost Monitoring
# Based on docs/finops/cost-analysis-and-budgets.md

terraform {
  required_version = ">= 1.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

# Staging Budget Alert ($150/month threshold)
resource "google_billing_budget" "staging" {
  count = var.environment == "staging" ? 1 : 0

  billing_account = var.billing_account
  display_name    = "Adyela ${var.environment} Budget"

  budget_filter {
    projects = ["projects/${var.project_id}"]
    labels = {
      environment = var.environment
    }
  }

  amount {
    specified_amount {
      currency_code = "USD"
      units         = tostring(var.budget_amount)
    }
  }

  # Alerts at 50%, 75%, 90%, 100%, 110%
  threshold_rules {
    threshold_percent = 0.5
    spend_basis       = "CURRENT_SPEND"
  }

  threshold_rules {
    threshold_percent = 0.75
    spend_basis       = "CURRENT_SPEND"
  }

  threshold_rules {
    threshold_percent = 0.9
    spend_basis       = "CURRENT_SPEND"
  }

  threshold_rules {
    threshold_percent = 1.0
    spend_basis       = "CURRENT_SPEND"
  }

  threshold_rules {
    threshold_percent = 1.1
    spend_basis       = "CURRENT_SPEND"
  }

  # Email notifications
  all_updates_rule {
    pubsub_topic              = google_pubsub_topic.budget_alerts.id
    disable_default_iam_recipients = false
    monitoring_notification_channels = var.notification_channel_ids
  }
}

# Production Budget Alert (tiered by usage)
resource "google_billing_budget" "production" {
  count = var.environment == "production" ? 1 : 0

  billing_account = var.billing_account
  display_name    = "Adyela ${var.environment} Budget"

  budget_filter {
    projects = ["projects/${var.project_id}"]
    labels = {
      environment = var.environment
    }
  }

  amount {
    specified_amount {
      currency_code = "USD"
      units         = tostring(var.budget_amount)
    }
  }

  # More aggressive thresholds for production
  threshold_rules {
    threshold_percent = 0.5
    spend_basis       = "CURRENT_SPEND"
  }

  threshold_rules {
    threshold_percent = 0.75
    spend_basis       = "CURRENT_SPEND"
  }

  threshold_rules {
    threshold_percent = 0.9
    spend_basis       = "CURRENT_SPEND"
  }

  threshold_rules {
    threshold_percent = 0.95
    spend_basis       = "CURRENT_SPEND"
  }

  threshold_rules {
    threshold_percent = 1.0
    spend_basis       = "CURRENT_SPEND"
  }

  all_updates_rule {
    pubsub_topic              = google_pubsub_topic.budget_alerts.id
    disable_default_iam_recipients = false
    monitoring_notification_channels = var.notification_channel_ids
  }
}

# Pub/Sub topic for budget alerts
resource "google_pubsub_topic" "budget_alerts" {
  name    = "${var.environment}-budget-alerts"
  project = var.project_id

  labels = {
    environment = var.environment
    type        = "budget-alert"
    managed-by  = "terraform"
  }
}

# Pub/Sub subscription for budget alerts (push to Cloud Function or webhook)
resource "google_pubsub_subscription" "budget_alerts" {
  name    = "${var.environment}-budget-alerts-sub"
  topic   = google_pubsub_topic.budget_alerts.name
  project = var.project_id

  # If webhook URL provided, use push; otherwise pull
  dynamic "push_config" {
    for_each = var.budget_alert_webhook_url != "" ? [1] : []
    content {
      push_endpoint = var.budget_alert_webhook_url
    }
  }

  ack_deadline_seconds = 60

  labels = {
    environment = var.environment
    type        = "budget-alert"
    managed-by  = "terraform"
  }
}

# Cost allocation labels (for multi-tenant attribution)
resource "google_monitoring_notification_channel" "email" {
  for_each = toset(var.alert_email_addresses)

  display_name = "Budget Alert - ${each.value}"
  type         = "email"
  project      = var.project_id

  labels = {
    email_address = each.value
  }

  enabled = true
}

# Monitoring alert for unusual cost spikes
resource "google_monitoring_alert_policy" "cost_spike" {
  display_name = "${var.environment} - Cost Spike Alert"
  project      = var.project_id
  combiner     = "OR"

  conditions {
    display_name = "Cost increase > 50% in 1 hour"

    condition_threshold {
      filter          = "metric.type=\"billing.googleapis.com/billing_account/cost\" resource.type=\"billing_account\""
      duration        = "3600s"
      comparison      = "COMPARISON_GT"
      threshold_value = var.budget_amount * 0.5 / 730 # 50% of monthly budget per hour

      aggregations {
        alignment_period   = "3600s"
        per_series_aligner = "ALIGN_RATE"
      }
    }
  }

  notification_channels = [for channel in google_monitoring_notification_channel.email : channel.id]

  alert_strategy {
    auto_close = "86400s" # 24 hours
  }

  enabled = var.enable_cost_spike_alerts
}
