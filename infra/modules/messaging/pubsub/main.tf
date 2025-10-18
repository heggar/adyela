# Pub/Sub Topics and Subscriptions for Event-Driven Architecture

terraform {
  required_version = ">= 1.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

# Topic for appointment events
resource "google_pubsub_topic" "appointments" {
  name    = "${var.environment}-appointments-events"
  project = var.project_id

  labels = {
    environment = var.environment
    service     = "appointments"
    managed-by  = "terraform"
  }

  message_retention_duration = "86400s" # 24 hours
}

# Topic for notification events
resource "google_pubsub_topic" "notifications" {
  name    = "${var.environment}-notifications-events"
  project = var.project_id

  labels = {
    environment = var.environment
    service     = "notifications"
    managed-by  = "terraform"
  }

  message_retention_duration = "86400s"
}

# Topic for payment events
resource "google_pubsub_topic" "payments" {
  name    = "${var.environment}-payments-events"
  project = var.project_id

  labels = {
    environment = var.environment
    service     = "payments"
    managed-by  = "terraform"
  }

  message_retention_duration = "86400s"
}

# Topic for analytics events
resource "google_pubsub_topic" "analytics" {
  name    = "${var.environment}-analytics-events"
  project = var.project_id

  labels = {
    environment = var.environment
    service     = "analytics"
    managed-by  = "terraform"
  }

  message_retention_duration = "604800s" # 7 days for analytics
}

# Dead letter topic for failed messages
resource "google_pubsub_topic" "dead_letter" {
  name    = "${var.environment}-dead-letter-topic"
  project = var.project_id

  labels = {
    environment = var.environment
    type        = "dead-letter"
    managed-by  = "terraform"
  }

  message_retention_duration = "604800s" # 7 days
}

# Subscription for notifications service (listens to appointments topic)
resource "google_pubsub_subscription" "notifications_appointments" {
  name    = "${var.environment}-notifications-appointments-sub"
  topic   = google_pubsub_topic.appointments.name
  project = var.project_id

  # Push subscription to Cloud Run service
  push_config {
    push_endpoint = var.notifications_service_url
    oidc_token {
      service_account_email = var.notifications_service_account
    }
  }

  # Retry policy
  retry_policy {
    minimum_backoff = "10s"
    maximum_backoff = "600s"
  }

  # Dead letter policy
  dead_letter_policy {
    dead_letter_topic     = google_pubsub_topic.dead_letter.id
    max_delivery_attempts = 5
  }

  # Expiration policy (30 days of inactivity)
  expiration_policy {
    ttl = "2592000s"
  }

  ack_deadline_seconds = 60

  labels = {
    environment = var.environment
    source      = "appointments"
    target      = "notifications"
    managed-by  = "terraform"
  }
}

# Subscription for analytics service (listens to multiple topics)
resource "google_pubsub_subscription" "analytics_appointments" {
  name    = "${var.environment}-analytics-appointments-sub"
  topic   = google_pubsub_topic.appointments.name
  project = var.project_id

  push_config {
    push_endpoint = var.analytics_service_url
    oidc_token {
      service_account_email = var.analytics_service_account
    }
  }

  retry_policy {
    minimum_backoff = "10s"
    maximum_backoff = "600s"
  }

  dead_letter_policy {
    dead_letter_topic     = google_pubsub_topic.dead_letter.id
    max_delivery_attempts = 5
  }

  ack_deadline_seconds = 60

  labels = {
    environment = var.environment
    source      = "appointments"
    target      = "analytics"
    managed-by  = "terraform"
  }
}

resource "google_pubsub_subscription" "analytics_payments" {
  name    = "${var.environment}-analytics-payments-sub"
  topic   = google_pubsub_topic.payments.name
  project = var.project_id

  push_config {
    push_endpoint = var.analytics_service_url
    oidc_token {
      service_account_email = var.analytics_service_account
    }
  }

  retry_policy {
    minimum_backoff = "10s"
    maximum_backoff = "600s"
  }

  dead_letter_policy {
    dead_letter_topic     = google_pubsub_topic.dead_letter.id
    max_delivery_attempts = 5
  }

  ack_deadline_seconds = 60

  labels = {
    environment = var.environment
    source      = "payments"
    target      = "analytics"
    managed-by  = "terraform"
  }
}

# IAM binding for dead letter topic
resource "google_pubsub_topic_iam_member" "dead_letter_publisher" {
  project = var.project_id
  topic   = google_pubsub_topic.dead_letter.name
  role    = "roles/pubsub.publisher"
  member  = "serviceAccount:service-${data.google_project.project.number}@gcp-sa-pubsub.iam.gserviceaccount.com"
}

resource "google_pubsub_subscription_iam_member" "dead_letter_subscriber" {
  project      = var.project_id
  subscription = google_pubsub_subscription.notifications_appointments.name
  role         = "roles/pubsub.subscriber"
  member       = "serviceAccount:service-${data.google_project.project.number}@gcp-sa-pubsub.iam.gserviceaccount.com"
}

data "google_project" "project" {
  project_id = var.project_id
}
