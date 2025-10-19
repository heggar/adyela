# Complete Microservice Deployment Example
#
# This example demonstrates how to deploy a complete microservice stack using
# all available Terraform modules: labels, Artifact Registry, Cloud Build, and Cloud Run.
#
# This configuration creates:
# - Standard labels for cost attribution and compliance
# - Docker container registry with cleanup policies
# - CI/CD pipeline triggered on git push
# - Cloud Run service with autoscaling and secrets

terraform {
  required_version = ">= 1.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.0"
    }
  }
}

# Configure GCP provider
provider "google" {
  project = var.project_id
  region  = var.region
}

# ============================================================================
# COMMON LABELS
# ============================================================================

module "labels" {
  source = "../../modules/common"

  # Required
  environment  = var.environment
  project_name = "adyela"
  team         = "backend"
  owner        = "api-team"

  # Cost tracking
  cost_center = "engineering"
  billing_id  = "adyela-eng-2024"

  # Application metadata
  application = "api"
  component   = "appointments"
  service     = "adyela-api-${var.environment}"
  tier        = "backend"
  version     = "v1_0_0"

  # Compliance (HIPAA)
  compliance_required = "hipaa"
  data_classification = "restricted"
  hipaa_scope         = "yes"

  # Operations
  backup_policy     = var.environment == "production" ? "daily" : "weekly"
  disaster_recovery = var.environment == "production" ? "critical" : "medium"
  high_availability = var.environment == "production" ? "true" : "false"
  contact_email     = "api-team@adyela.com"

  # Custom labels
  custom_labels = {
    microservice = "appointments"
    api_version  = "v1"
  }
}

# ============================================================================
# ARTIFACT REGISTRY (Docker Container Registry)
# ============================================================================

module "container_registry" {
  source = "../../modules/artifact-registry"

  project_id    = var.project_id
  repository_id = "adyela"
  location      = var.region
  environment   = var.environment

  description = "Docker images for Adyela microservices (${var.environment})"

  # Cleanup policies to save storage costs
  cleanup_policies = var.environment == "production" ? [
    # Production: Keep recent versions
    {
      id     = "keep-recent-50-versions"
      action = "KEEP"
      most_recent_versions = {
        keep_count = 50
      }
    },
    # Delete untagged images after 30 days
    {
      id     = "delete-old-untagged"
      action = "DELETE"
      condition = {
        tag_state  = "UNTAGGED"
        older_than = "2592000s" # 30 days
      }
    }
    ] : [
    # Staging: More aggressive cleanup
    {
      id     = "keep-recent-10-versions"
      action = "KEEP"
      most_recent_versions = {
        keep_count = 10
      }
    },
    {
      id     = "delete-old-7-days"
      action = "DELETE"
      condition = {
        older_than = "604800s" # 7 days
      }
    }
  ]

  # Immutable tags in production (prevent overwrites)
  immutable_tags = var.environment == "production"

  # Create service account for GitHub Actions CI/CD
  create_cicd_service_account = true
  grant_storage_admin         = true

  # Apply standard labels
  labels = module.labels.cicd_labels
}

# ============================================================================
# CLOUD BUILD (CI/CD Pipeline)
# ============================================================================

module "api_build_pipeline" {
  source = "../../modules/cloud-build"

  project_id   = var.project_id
  trigger_name = "api-${var.environment}-deploy"
  environment  = var.environment
  description  = "Build and deploy API service to ${var.environment}"

  # GitHub trigger configuration
  github_config = {
    owner     = var.github_owner
    repo_name = var.github_repo

    # Trigger on push to main (staging) or tags (production)
    push_config = var.environment == "production" ? {
      tag = "^v[0-9]+\\.[0-9]+\\.[0-9]+$" # Match semver tags: v1.2.3
      } : {
      branch = "^main$"
    }
  }

  # Use cloudbuild.yaml from repository
  build_config_file = "apps/api/cloudbuild.yaml"

  # Variables available in cloudbuild.yaml as $_VARIABLE
  substitutions = {
    _ENVIRONMENT    = var.environment
    _REGION         = var.region
    _SERVICE_NAME   = "adyela-api-${var.environment}"
    _REPOSITORY_URL = module.container_registry.repository_url
    _PROJECT_ID     = var.project_id
  }

  # Only trigger builds when API code changes (not on README updates)
  included_files = [
    "apps/api/**",
    "apps/api/cloudbuild.yaml"
  ]

  # Ignore documentation changes
  ignored_files = [
    "apps/api/README.md",
    "apps/api/docs/**",
    "*.md"
  ]

  # Production requires manual approval
  require_approval = var.environment == "production"

  # Create dedicated service account with required permissions
  create_service_account         = true
  grant_artifact_registry_access = true # Push to Artifact Registry
  grant_cloud_run_access         = true # Deploy to Cloud Run
  grant_secret_access            = true # Access Secret Manager

  # Allow Cloud Build to deploy as the Cloud Run service account
  cloud_run_service_account = module.api_service.service_account_id

  # Apply standard tags
  tags = module.labels.tags
}

# ============================================================================
# CLOUD RUN SERVICE (Serverless Container)
# ============================================================================

module "api_service" {
  source = "../../modules/cloud-run-service"

  project_id   = var.project_id
  service_name = "adyela-api-${var.environment}"
  location     = var.region
  environment  = var.environment

  # Container image from Artifact Registry
  image = "${module.container_registry.repository_url}/api:latest"

  # Autoscaling configuration
  min_instances = var.environment == "production" ? 1 : 0 # Production: always warm
  max_instances = var.environment == "production" ? 20 : 10

  # Resource limits
  cpu_limit    = "1000m" # 1 vCPU
  memory_limit = "512Mi"

  # Timeout and concurrency
  timeout               = 300 # 5 minutes
  max_instance_requests = 80

  # Environment variables (non-sensitive)
  env_vars = {
    ENVIRONMENT       = var.environment
    LOG_LEVEL         = var.environment == "production" ? "INFO" : "DEBUG"
    CORS_ORIGINS      = var.environment == "production" ? "https://adyela.com" : "*"
    FIRESTORE_PROJECT = var.project_id
    REGION            = var.region
  }

  # Secrets from Secret Manager (sensitive values)
  secrets = {
    DATABASE_URL = {
      secret  = "firestore-connection-string"
      version = "latest"
    }
    JWT_SECRET = {
      secret  = "jwt-secret-${var.environment}"
      version = "latest"
    }
    SENDGRID_API_KEY = {
      secret  = "sendgrid-api-key"
      version = "latest"
    }
  }

  # Health checks
  startup_probe = {
    path              = "/health"
    initial_delay     = 5
    timeout           = 3
    period            = 10
    failure_threshold = 3
  }

  liveness_probe = {
    path              = "/health"
    timeout           = 3
    period            = 30
    failure_threshold = 2
  }

  # Network configuration
  # Production: Use VPC connector for private Firestore access
  # Staging: Direct internet access (simpler, lower cost)
  vpc_connector = var.environment == "production" ? var.vpc_connector_name : null

  # IAM: Production is private (Cloud CDN + IAP), staging is public
  allow_public_access = var.environment != "production"

  # Apply standard labels
  labels = module.labels.compute_labels
}

# ============================================================================
# OUTPUTS
# ============================================================================

output "service_url" {
  description = "URL of the deployed Cloud Run service"
  value       = module.api_service.service_url
}

output "repository_url" {
  description = "Artifact Registry repository URL for pushing images"
  value       = module.container_registry.repository_url
}

output "cicd_service_account" {
  description = "Service account email for CI/CD (use in GitHub Actions)"
  value       = module.container_registry.cicd_service_account_email
}

output "build_trigger_id" {
  description = "Cloud Build trigger ID"
  value       = module.api_build_pipeline.trigger_id
}

output "labels" {
  description = "Standard labels applied to all resources"
  value       = module.labels.labels
}
