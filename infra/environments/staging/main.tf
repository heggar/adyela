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

# Local variables
locals {
  environment = "staging"
  labels = {
    environment = local.environment
    managed-by  = "terraform"
    hipaa       = "ready"
    cost-center = "engineering"
  }
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

  # Minimal resources for cost optimization
  connector_min_instances = 2
  connector_max_instances = 3
  connector_machine_type  = "f1-micro"

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
# Load Balancer Module - HIPAA-Compliant Public Access with IAP
# Cost: ~$18-25/month
# Provides: Public access with mandatory authentication via Identity-Aware Proxy
# 
# NOTE: Temporarily commented out to resolve CI - Infrastructure errors
# The Load Balancer resources are already created manually and working
# IP: 34.96.108.162, Domain: staging.adyela.care
# ================================================================================

module "load_balancer" {
  source = "../../modules/load-balancer"

  project_id     = var.project_id
  project_name   = var.project_name
  environment    = local.environment
  region         = var.region
  domain         = "staging.adyela.care"

  # Cloud Run services
  cloud_run_service_name = "adyela-web-staging"
  api_service_name       = "adyela-api-staging"

  # IAP configuration
  iap_enabled = true

  labels = local.labels
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
  vpc_connector_name    = module.vpc.vpc_connector_name

  # Docker images - these will be updated by CI/CD
  api_image = "us-central1-docker.pkg.dev/${var.project_id}/adyela/adyela-api-staging:latest"
  web_image = "us-central1-docker.pkg.dev/${var.project_id}/adyela/adyela-web-staging:latest"

  # HIPAA Secrets
  hipaa_secrets = {
    SECRET_KEY          = "api-secret-key"
    FIREBASE_PROJECT_ID = "firebase-project-id"
    FIREBASE_ADMIN_KEY  = "firebase-admin-key"
    JWT_SECRET          = "jwt-secret-key"
    ENCRYPTION_KEY      = "encryption-key"
    DATABASE_URL        = "database-connection-string"
    SMTP_CREDENTIALS    = "smtp-credentials"
    EXTERNAL_API_KEYS   = "external-api-keys"
  }

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
