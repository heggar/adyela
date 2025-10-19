# Staging Environment - All Microservices Deployment
# This file deploys the 6 microservices using the reusable cloud-run-service module

# ============================================================================
# MICROSERVICE 1: API Auth
# ============================================================================
module "api_auth" {
  source = "../../modules/cloud-run-service"

  project_id   = var.project_id
  region       = var.region
  service_name = "api-auth-staging"
  environment  = "staging"

  # Container configuration
  container_image = "${var.region}-docker.pkg.dev/${var.project_id}/adyela/api-auth:latest"
  container_port  = 8000

  # Resources - optimized for staging
  cpu_limit             = "1"
  memory_limit          = "512Mi"
  cpu_always_allocated  = false # Scale-to-zero enabled
  cpu_throttling        = true
  startup_cpu_boost     = true
  execution_environment = "gen2"

  # Scaling
  min_instances           = 0 # Scale-to-zero for cost optimization
  max_instances           = 5
  max_concurrent_requests = 80

  # Health checks
  enable_health_checks = true
  health_check_path    = "/health"
  timeout_seconds      = 60

  # Service account
  create_service_account = true
  service_account_roles = [
    "roles/cloudtrace.agent",
    "roles/logging.logWriter",
    "roles/monitoring.metricWriter",
    "roles/secretmanager.secretAccessor",
    "roles/datastore.user", # Firestore access
  ]

  # Environment variables
  environment_variables = {
    ENVIRONMENT        = "staging"
    PROJECT_ID         = var.project_id
    REGION             = var.region
    LOG_LEVEL          = "INFO"
    FIRESTORE_DATABASE = "(default)"
    CORS_ORIGINS       = "https://staging.adyela.care,https://admin.staging.adyela.care,https://patient.staging.adyela.care,https://professional.staging.adyela.care"
  }

  # Secrets from Secret Manager
  secret_environment_variables = {
    FIREBASE_API_KEY = {
      secret  = "firebase-api-key-staging"
      version = "latest"
    }
    JWT_SECRET = {
      secret  = "jwt-secret-staging"
      version = "latest"
    }
  }

  # Access control
  allow_unauthenticated = true # Public auth endpoints
  invoker_members       = []

  # Labels for cost attribution
  tier = "shared"
  labels = {
    component = "authentication"
    tier      = "core"
  }
}

# ============================================================================
# MICROSERVICE 2: API Appointments
# ============================================================================
module "api_appointments" {
  source = "../../modules/cloud-run-service"

  project_id   = var.project_id
  region       = var.region
  service_name = "api-appointments-staging"
  environment  = "staging"

  container_image = "${var.region}-docker.pkg.dev/${var.project_id}/adyela/api-appointments:latest"
  container_port  = 8000

  # Resources
  cpu_limit            = "1"
  memory_limit         = "512Mi"
  cpu_always_allocated = false
  cpu_throttling       = true
  startup_cpu_boost    = true

  # Scaling
  min_instances           = 0
  max_instances           = 10
  max_concurrent_requests = 80

  # Health checks
  enable_health_checks = true
  health_check_path    = "/health"
  timeout_seconds      = 60

  # Service account
  create_service_account = true
  service_account_roles = [
    "roles/cloudtrace.agent",
    "roles/logging.logWriter",
    "roles/monitoring.metricWriter",
    "roles/secretmanager.secretAccessor",
    "roles/datastore.user",
    "roles/pubsub.publisher", # Publish appointment events
  ]

  environment_variables = {
    ENVIRONMENT       = "staging"
    PROJECT_ID        = var.project_id
    REGION            = var.region
    LOG_LEVEL         = "INFO"
    AUTH_SERVICE_URL  = module.api_auth.service_url
    PUBSUB_TOPIC_NAME = module.pubsub.appointments_topic_name
  }

  secret_environment_variables = {
    JWT_SECRET = {
      secret  = "jwt-secret-staging"
      version = "latest"
    }
  }

  # Requires authentication (called by authenticated users)
  allow_unauthenticated = false
  invoker_members = [
    "serviceAccount:${module.api_auth.service_account_email}",
    "allUsers", # TODO: Remove after implementing proper service-to-service auth
  ]

  tier = "shared"
  labels = {
    component = "appointments"
    tier      = "core"
  }
}

# ============================================================================
# MICROSERVICE 3: API Payments (Node.js)
# ============================================================================
module "api_payments" {
  source = "../../modules/cloud-run-service"

  project_id   = var.project_id
  region       = var.region
  service_name = "api-payments-staging"
  environment  = "staging"

  container_image = "${var.region}-docker.pkg.dev/${var.project_id}/adyela/api-payments:latest"
  container_port  = 3000 # Node.js default

  # Resources
  cpu_limit            = "1"
  memory_limit         = "512Mi"
  cpu_always_allocated = false
  cpu_throttling       = true

  # Scaling
  min_instances           = 0
  max_instances           = 5
  max_concurrent_requests = 80

  # Health checks
  enable_health_checks = true
  health_check_path    = "/health"
  timeout_seconds      = 60

  # Service account
  create_service_account = true
  service_account_roles = [
    "roles/cloudtrace.agent",
    "roles/logging.logWriter",
    "roles/monitoring.metricWriter",
    "roles/secretmanager.secretAccessor",
    "roles/pubsub.publisher",
  ]

  environment_variables = {
    NODE_ENV          = "staging"
    PROJECT_ID        = var.project_id
    REGION            = var.region
    LOG_LEVEL         = "info"
    AUTH_SERVICE_URL  = module.api_auth.service_url
    PUBSUB_TOPIC_NAME = module.pubsub.payments_topic_name
  }

  secret_environment_variables = {
    STRIPE_SECRET_KEY = {
      secret  = "stripe-secret-key-staging"
      version = "latest"
    }
    STRIPE_WEBHOOK_SECRET = {
      secret  = "stripe-webhook-secret-staging"
      version = "latest"
    }
  }

  allow_unauthenticated = false
  invoker_members       = ["allUsers"] # TODO: Restrict after proper auth

  tier = "shared"
  labels = {
    component = "payments"
    tier      = "premium"
  }
}

# ============================================================================
# MICROSERVICE 4: API Notifications (Node.js)
# ============================================================================
module "api_notifications" {
  source = "../../modules/cloud-run-service"

  project_id   = var.project_id
  region       = var.region
  service_name = "api-notifications-staging"
  environment  = "staging"

  container_image = "${var.region}-docker.pkg.dev/${var.project_id}/adyela/api-notifications:latest"
  container_port  = 3000

  # Resources
  cpu_limit            = "1" # Minimum 1 CPU required for concurrency > 1
  memory_limit         = "512Mi"
  cpu_always_allocated = false
  cpu_throttling       = true

  # Scaling
  min_instances           = 0
  max_instances           = 10 # Can scale higher for burst notifications
  max_concurrent_requests = 100

  # Health checks
  enable_health_checks = true
  health_check_path    = "/health"
  timeout_seconds      = 60

  # Service account
  create_service_account = true
  service_account_roles = [
    "roles/cloudtrace.agent",
    "roles/logging.logWriter",
    "roles/monitoring.metricWriter",
    "roles/secretmanager.secretAccessor",
    "roles/pubsub.subscriber",
  ]

  environment_variables = {
    NODE_ENV   = "staging"
    PROJECT_ID = var.project_id
    REGION     = var.region
    LOG_LEVEL  = "info"
  }

  secret_environment_variables = {
    SENDGRID_API_KEY = {
      secret  = "sendgrid-api-key-staging"
      version = "latest"
    }
    TWILIO_ACCOUNT_SID = {
      secret  = "twilio-account-sid-staging"
      version = "latest"
    }
    TWILIO_AUTH_TOKEN = {
      secret  = "twilio-auth-token-staging"
      version = "latest"
    }
  }

  allow_unauthenticated = false
  invoker_members = [
    "serviceAccount:service-${data.google_project.project.number}@gcp-sa-pubsub.iam.gserviceaccount.com", # Pub/Sub
  ]

  tier = "shared"
  labels = {
    component = "notifications"
    tier      = "core"
  }
}

# ============================================================================
# MICROSERVICE 5: API Admin
# ============================================================================
module "api_admin" {
  source = "../../modules/cloud-run-service"

  project_id   = var.project_id
  region       = var.region
  service_name = "api-admin-staging"
  environment  = "staging"

  container_image = "${var.region}-docker.pkg.dev/${var.project_id}/adyela/api-admin:latest"
  container_port  = 8000

  # Resources
  cpu_limit            = "1"
  memory_limit         = "512Mi"
  cpu_always_allocated = false
  cpu_throttling       = true

  # Scaling
  min_instances           = 0
  max_instances           = 3 # Lower max for admin
  max_concurrent_requests = 50

  # Health checks
  enable_health_checks = true
  health_check_path    = "/health"
  timeout_seconds      = 120 # Longer timeout for admin operations

  # Service account
  create_service_account = true
  service_account_roles = [
    "roles/cloudtrace.agent",
    "roles/logging.logWriter",
    "roles/monitoring.metricWriter",
    "roles/secretmanager.secretAccessor",
    "roles/datastore.user",
    "roles/iam.serviceAccountUser", # Manage user permissions
  ]

  environment_variables = {
    ENVIRONMENT      = "staging"
    PROJECT_ID       = var.project_id
    REGION           = var.region
    LOG_LEVEL        = "INFO"
    AUTH_SERVICE_URL = module.api_auth.service_url
  }

  secret_environment_variables = {
    JWT_SECRET = {
      secret  = "jwt-secret-staging"
      version = "latest"
    }
    ADMIN_SECRET = {
      secret  = "admin-secret-staging"
      version = "latest"
    }
  }

  allow_unauthenticated = false
  invoker_members       = ["allUsers"] # TODO: Restrict to admin users only

  tier = "shared"
  labels = {
    component = "admin"
    tier      = "core"
  }
}

# ============================================================================
# MICROSERVICE 6: API Analytics
# ============================================================================
module "api_analytics" {
  source = "../../modules/cloud-run-service"

  project_id   = var.project_id
  region       = var.region
  service_name = "api-analytics-staging"
  environment  = "staging"

  container_image = "${var.region}-docker.pkg.dev/${var.project_id}/adyela/api-analytics:latest"
  container_port  = 8000

  # Resources - can be lower for analytics processing
  cpu_limit            = "1"
  memory_limit         = "1Gi" # More memory for data processing
  cpu_always_allocated = false
  cpu_throttling       = true

  # Scaling
  min_instances           = 0
  max_instances           = 5
  max_concurrent_requests = 50

  # Health checks
  enable_health_checks = true
  health_check_path    = "/health"
  timeout_seconds      = 120

  # Service account
  create_service_account = true
  service_account_roles = [
    "roles/cloudtrace.agent",
    "roles/logging.logWriter",
    "roles/monitoring.metricWriter",
    "roles/secretmanager.secretAccessor",
    "roles/datastore.user",
    "roles/pubsub.subscriber",
    "roles/bigquery.dataEditor", # For analytics storage
  ]

  environment_variables = {
    ENVIRONMENT      = "staging"
    PROJECT_ID       = var.project_id
    REGION           = var.region
    LOG_LEVEL        = "INFO"
    BIGQUERY_DATASET = "adyela_analytics_staging"
  }

  secret_environment_variables = {}

  allow_unauthenticated = false
  invoker_members = [
    "serviceAccount:service-${data.google_project.project.number}@gcp-sa-pubsub.iam.gserviceaccount.com", # Pub/Sub
  ]

  tier = "shared"
  labels = {
    component = "analytics"
    tier      = "analytics"
  }
}

# ============================================================================
# PUB/SUB MESSAGING
# ============================================================================
module "pubsub" {
  source = "../../modules/messaging/pubsub"

  project_id  = var.project_id
  environment = "staging"

  # Service URLs and accounts (depends on microservices being created)
  notifications_service_url     = "${module.api_notifications.service_url}/webhooks/pubsub"
  notifications_service_account = module.api_notifications.service_account_email
  analytics_service_url         = "${module.api_analytics.service_url}/webhooks/pubsub"
  analytics_service_account     = module.api_analytics.service_account_email
}

# ============================================================================
# FINOPS - BUDGET ALERTS
# ============================================================================
module "finops" {
  source = "../../modules/finops"

  project_id      = var.project_id
  billing_account = var.billing_account
  environment     = "staging"

  # Staging budget: $150/month (as per docs/finops/cost-analysis-and-budgets.md)
  budget_amount = 150

  # Alert email addresses
  alert_email_addresses = var.budget_alert_emails

  # Enable cost spike detection
  enable_cost_spike_alerts = true
}

# ============================================================================
# DATA
# ============================================================================
data "google_project" "project" {
  project_id = var.project_id
}
