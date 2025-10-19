# ================================================================================
# Flutter Web Applications - Patient and Professional Apps
# Cost: ~$0/month (scale-to-zero, only active when in use)
# ================================================================================

# ============================================================================
# Patient App (Flutter Web)
# ============================================================================

module "flutter_web_patient" {
  source = "../../modules/cloud-run-service"

  project_id   = var.project_id
  service_name = "adyela-patient-web-staging"
  region       = var.region
  environment  = local.environment

  # Container configuration
  container_image = "us-central1-docker.pkg.dev/${var.project_id}/adyela/adyela-patient-web-staging:latest"
  container_port  = 8080

  # Resource limits - Flutter web is lightweight
  cpu_limit    = "1000m" # 1 vCPU
  memory_limit = "512Mi" # 512 MB

  # Cost optimization
  cpu_always_allocated = false # CPU allocated only when processing requests
  cpu_throttling       = true  # Throttle CPU when idle
  startup_cpu_boost    = true  # Boost for faster startup

  # Scaling - scale-to-zero for cost savings
  min_instances = 0
  max_instances = 10

  # Timeout
  timeout_seconds = 60

  # Concurrency
  max_concurrent_requests = 80

  # Health checks
  enable_health_checks = true
  health_check_path    = "/" # Flutter web serves index.html at root

  # Service account
  service_account_email  = module.service_account.service_account_email
  create_service_account = false

  # Public access (authentication handled by app)
  allow_unauthenticated = true
  invoker_members       = []

  # Environment variables
  environment_variables = {
    ENVIRONMENT = "staging"
    API_URL     = "https://api.staging.adyela.care"
    APP_VERSION = "terraform-managed"
    # Flutter web runtime configuration
    FLUTTER_WEB_USE_SKIA             = "true"
    FLUTTER_WEB_CANVASKIT_FORCE_CPU  = "false"
    FLUTTER_WEB_AUTO_DETECT_RENDERER = "true"
  }

  # No secrets needed for patient app (uses Firebase Auth)
  secret_environment_variables = {}

  # Execution environment
  execution_environment = "gen2" # Second generation Cloud Run

  # Tier for billing
  tier = "frontend"

  # Labels
  labels = merge(
    local.labels,
    {
      app-type  = "flutter-web"
      user-role = "patient"
      cost-tier = "staging"
    }
  )
}

# ============================================================================
# Professional App (Flutter Web)
# ============================================================================

module "flutter_web_professional" {
  source = "../../modules/cloud-run-service"

  project_id   = var.project_id
  service_name = "adyela-professional-web-staging"
  region       = var.region
  environment  = local.environment

  # Container configuration
  container_image = "us-central1-docker.pkg.dev/${var.project_id}/adyela/adyela-professional-web-staging:latest"
  container_port  = 8080

  # Resource limits - Flutter web is lightweight
  cpu_limit    = "1000m" # 1 vCPU
  memory_limit = "512Mi" # 512 MB

  # Cost optimization
  cpu_always_allocated = false
  cpu_throttling       = true
  startup_cpu_boost    = true

  # Scaling - scale-to-zero for cost savings
  min_instances = 0
  max_instances = 10

  # Timeout
  timeout_seconds = 60

  # Concurrency
  max_concurrent_requests = 80

  # Health checks
  enable_health_checks = true
  health_check_path    = "/"

  # Service account
  service_account_email  = module.service_account.service_account_email
  create_service_account = false

  # Public access (authentication handled by app)
  allow_unauthenticated = true
  invoker_members       = []

  # Environment variables
  environment_variables = {
    ENVIRONMENT = "staging"
    API_URL     = "https://api.staging.adyela.care"
    APP_VERSION = "terraform-managed"
    # Flutter web runtime configuration
    FLUTTER_WEB_USE_SKIA             = "true"
    FLUTTER_WEB_CANVASKIT_FORCE_CPU  = "false"
    FLUTTER_WEB_AUTO_DETECT_RENDERER = "true"
  }

  # No secrets needed for professional app (uses Firebase Auth)
  secret_environment_variables = {}

  # Execution environment
  execution_environment = "gen2"

  # Tier for billing
  tier = "frontend"

  # Labels
  labels = merge(
    local.labels,
    {
      app-type  = "flutter-web"
      user-role = "professional"
      cost-tier = "staging"
    }
  )
}

# ============================================================================
# Outputs
# ============================================================================

output "patient_web_service_name" {
  description = "Name of the patient web service"
  value       = module.flutter_web_patient.service_name
}

output "patient_web_service_url" {
  description = "URL of the patient web service"
  value       = module.flutter_web_patient.service_url
}

output "professional_web_service_name" {
  description = "Name of the professional web service"
  value       = module.flutter_web_professional.service_name
}

output "professional_web_service_url" {
  description = "URL of the professional web service"
  value       = module.flutter_web_professional.service_url
}
