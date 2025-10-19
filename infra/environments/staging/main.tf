terraform {
  required_version = ">= 1.5.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

# ============================================================================
# COMMON LABELS - Standardized labeling for all resources
# ============================================================================

module "labels" {
  source = "../../modules/common"

  # Required
  environment  = var.environment
  project_name = var.project_name
  team         = "platform"
  owner        = "devops-team"

  # Cost management
  cost_center = "engineering"
  billing_id  = "adyela-eng-2024"

  # Application metadata
  application = "adyela-platform"
  tier        = "backend"

  # Compliance (HIPAA)
  compliance_required = "hipaa"
  data_classification = "restricted"
  hipaa_scope         = "yes"

  # Operations
  backup_policy     = "weekly"
  disaster_recovery = "medium"
  high_availability = "false" # Staging uses scale-to-zero

  # Contact information
  contact_email = var.contact_email

  # Custom labels
  custom_labels = {
    cost_tier = "staging"
  }
}

# Local variables for backward compatibility
locals {
  environment = var.environment
  labels      = module.labels.labels # Use standardized labels from common module
}

# ================================================================================
# VPC Module - HIPAA-Ready Networking
# Cost: $0.00/month (Cloud NAT disabled for staging)
# ================================================================================

module "vpc" {
  source = "../../modules/vpc"

  project_id   = var.project_id
  network_name = "${var.project_name}-${local.environment}-vpc"
  environment  = local.environment
  region       = var.region

  # Staging-specific network ranges
  subnet_cidr    = "10.0.0.0/24"
  connector_cidr = "10.8.0.0/28"

  # Deshabilitar VPC Connector en staging para ahorro de $64/mes
  enable_vpc_connector = false

  # Configuración mínima (solo necesaria si enable_vpc_connector = true)
  # connector_min_instances = 1  # Comentado - no usado
  # connector_max_instances = 2  # Comentado - no usado
  # connector_machine_type  = "f1-micro"  # Comentado - no usado

  # Disable Cloud NAT in staging (no external API calls)
  # If needed later, set to true (adds ~$32/month)
  enable_cloud_nat = false

  labels = local.labels
}

# ================================================================================
# Service Account Module - HIPAA-Compliant
# Cost: $0.00/month (FREE)
# Required for: Secure Cloud Run deployments, Secret Manager access
# ================================================================================

module "service_account" {
  source = "../../modules/service-account"

  project_id   = var.project_id
  project_name = var.project_name
  environment  = local.environment

  labels = local.labels
}

# ================================================================================
# Load Balancer Module - ENABLED FOR STAGING
# Cost: ~$18-25/month
#
# MANTENER EN STAGING:
# - DNS personalizado ya configurado (staging.adyela.care)
# - SSL certificate activo
# - URLs limpias para testing
# - Misma arquitectura que production
#
# OPTIMIZACIÓN: Sin Cloud Armor (ahorro de $17/mes)
# - Cloud Armor se agrega solo en production
# - Staging no necesita WAF protection
# ================================================================================

module "load_balancer" {
  source = "../../modules/load-balancer"

  project_id   = var.project_id
  project_name = var.project_name
  environment  = local.environment
  region       = var.region
  domain       = "staging.adyela.care"

  # Cloud Run services
  cloud_run_service_name    = "adyela-web-staging"
  api_service_name          = "adyela-api-staging"
  patient_service_name      = module.flutter_web_patient.service_name
  professional_service_name = module.flutter_web_professional.service_name

  # Microservices path-based routing (Strangler Pattern)
  # Gradually migrate endpoints from legacy API to microservices
  microservices = {
    auth = {
      service_name = module.api_auth.service_name
      path_prefix  = "/auth"
    }
    appointments = {
      service_name = module.api_appointments.service_name
      path_prefix  = "/appointments"
    }
    payments = {
      service_name = module.api_payments.service_name
      path_prefix  = "/payments"
    }
    notifications = {
      service_name = module.api_notifications.service_name
      path_prefix  = "/notifications"
    }
    admin = {
      service_name = module.api_admin.service_name
      path_prefix  = "/admin"
    }
    analytics = {
      service_name = module.api_analytics.service_name
      path_prefix  = "/analytics"
    }
  }

  # IAP configuration - Disabled (auth via Identity Platform OAuth)
  # IAP is for internal apps with Google Workspace users
  # Patient authentication is handled by Identity Platform
  iap_enabled = false

  # Cloud Armor - DISABLED for staging (cost optimization)
  # security_policy_id will not be attached

  # CDN configuration
  enable_cdn = true

  labels = local.labels

  # Ensure all services are created before load balancer
  depends_on = [
    module.flutter_web_patient,
    module.flutter_web_professional,
    module.api_auth,
    module.api_appointments,
    module.api_payments,
    module.api_notifications,
    module.api_admin,
    module.api_analytics
  ]
}

# ================================================================================
# Cloud Run Module - HIPAA-Compliant Services
# ================================================================================

module "cloud_run" {
  source = "../../modules/cloud-run"

  project_id   = var.project_id
  project_name = var.project_name
  environment  = local.environment
  region       = var.region

  service_account_email = module.service_account.service_account_email
  vpc_connector_name    = null # Sin VPC Connector en staging

  # API URL for frontend (through load balancer with custom domain)
  api_url = "https://api.staging.adyela.care"

  # Docker images - CI/CD deploys directly, Terraform only for initial setup
  # These values are used ONLY for initial resource creation
  # CI/CD updates images directly via gcloud/Cloud Run API
  api_image = "us-central1-docker.pkg.dev/${var.project_id}/adyela/adyela-api-staging:latest"
  web_image = "us-central1-docker.pkg.dev/${var.project_id}/adyela/adyela-web-staging:latest"

  # Application version - placeholder for Terraform
  app_version = "terraform-managed"

  # Scaling configuration - Staging: scale-to-zero for cost savings
  min_instances = 0
  max_instances = 2

  # HIPAA Secrets
  hipaa_secrets = {
    SECRET_KEY                    = "api-secret-key"
    FIREBASE_PROJECT_ID           = "firebase-project-id"
    FIREBASE_ADMIN_KEY            = "firebase-admin-key"
    JWT_SECRET                    = "jwt-secret-key"
    ENCRYPTION_KEY                = "encryption-key"
    DATABASE_URL                  = "database-connection-string"
    SMTP_CREDENTIALS              = "smtp-credentials"
    EXTERNAL_API_KEYS             = "external-api-keys"
    OAUTH_GOOGLE_CLIENT_ID        = "oauth-google-client-id"
    OAUTH_GOOGLE_CLIENT_SECRET    = "oauth-google-client-secret"
    OAUTH_MICROSOFT_CLIENT_ID     = "oauth-microsoft-client-id"
    OAUTH_MICROSOFT_CLIENT_SECRET = "oauth-microsoft-client-secret"
    OAUTH_APPLE_CLIENT_ID         = "oauth-apple-client-id"
    OAUTH_APPLE_CLIENT_SECRET     = "oauth-apple-client-secret"
    OAUTH_FACEBOOK_APP_ID         = "oauth-facebook-app-id"
    OAUTH_FACEBOOK_APP_SECRET     = "oauth-facebook-app-secret"
  }

  labels = local.labels
}

# ================================================================================
# Monitoring Module - Uptime Checks & Alerts
# Cost: $0/month (first 3 uptime checks FREE)
# ================================================================================

module "monitoring" {
  source = "../../modules/monitoring"

  project_id   = var.project_id
  project_name = var.project_name
  environment  = local.environment
  domain       = "staging.adyela.care"

  # Alert configuration
  alert_email       = var.alert_email
  enable_sms_alerts = false # No SMS in staging ($0.30/mes ahorro)

  # ============================================================================
  # STAGING OPTIMIZATIONS - Disable advanced features
  # ============================================================================

  # Log Sinks - DISABLED ($0.20/mes ahorro)
  # Usa Cloud Logging console directamente para debugging
  enable_log_sinks = false

  # Error Reporting - KEEP BASIC
  # Útil para detectar errores durante testing
  enable_error_reporting_alerts = true

  # Cloud Trace - DISABLED
  # No necesario para 1-2 testers
  enable_trace_alerts = false
  trace_sampling_rate = 1.0 # 100% sampling si se habilita después

  # Microservices Dashboards - DISABLED
  # Un dashboard básico es suficiente para staging
  enable_microservices_dashboards = false

  # SLO Configuration - SIMPLIFIED
  # SLOs relajados para staging (no hay SLA real)
  availability_slo_target = 0.99 # 99% (vs 99.9% production)
  latency_slo_target_ms   = 2000 # 2s (vs 1s production)
  error_rate_slo_target   = 0.05 # 5% (vs 1% production)
  slo_rolling_period_days = 7    # 7 días (vs 30 production)

  # External Notifications - DISABLED
  enable_slack_notifications     = false
  enable_pagerduty_notifications = false

  labels = local.labels
}

# ================================================================================
# Outputs for other modules
# ================================================================================

output "vpc_network_name" {
  description = "VPC network name for use in other modules"
  value       = module.vpc.network_name
}

output "vpc_connector_name" {
  description = "VPC Access Connector name for Cloud Run"
  value       = module.vpc.vpc_connector_name
}

output "subnet_name" {
  description = "Private subnet name"
  value       = module.vpc.subnet_name
}

output "hipaa_service_account_email" {
  description = "Email of the HIPAA service account for Cloud Run deployments"
  value       = module.service_account.service_account_email
}

output "hipaa_service_account_id" {
  description = "ID of the HIPAA service account"
  value       = module.service_account.service_account_id
}

# Cloud Run outputs
output "api_service_name" {
  description = "Name of the API Cloud Run service"
  value       = module.cloud_run.api_service_name
}

output "api_service_url" {
  description = "URL of the API Cloud Run service"
  value       = module.cloud_run.api_service_url
}

output "web_service_name" {
  description = "Name of the Web Cloud Run service"
  value       = module.cloud_run.web_service_name
}

output "web_service_url" {
  description = "URL of the Web Cloud Run service"
  value       = module.cloud_run.web_service_url
}

# Load Balancer outputs - temporarily commented out
# The Load Balancer is working with IP: 34.96.108.162

# output "load_balancer_ip" {
#   description = "Global IP address of the load balancer for DNS configuration"
#   value       = module.load_balancer.load_balancer_ip
# }

# output "load_balancer_domain" {
#   description = "Domain configured for the load balancer"
#   value       = module.load_balancer.domain
# }

# output "ssl_certificate_name" {
#   description = "Name of the managed SSL certificate"
#   value       = module.load_balancer.ssl_certificate_name
# }

# output "iap_enabled" {
#   description = "Whether IAP is enabled for authentication"
#   value       = module.load_balancer.iap_enabled
# }

# Monitoring outputs
output "monitoring_dashboard_url" {
  description = "URL to the monitoring dashboard in GCP Console"
  value       = module.monitoring.dashboard_url
}
