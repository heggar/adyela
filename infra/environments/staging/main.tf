terraform {
  required_version = ">= 1.9.0"

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
