# VPC Module Variables

variable "network_name" {
  description = "Name of the VPC network"
  type        = string
}

variable "environment" {
  description = "Environment name (staging, production, dev)"
  type        = string
  validation {
    condition     = contains(["dev", "staging", "production"], var.environment)
    error_message = "Environment must be one of: dev, staging, production"
  }
}

variable "region" {
  description = "GCP region for resources"
  type        = string
  default     = "us-central1"
}

variable "subnet_cidr" {
  description = "CIDR range for the private subnet"
  type        = string
  default     = "10.0.0.0/24"
}

variable "connector_cidr" {
  description = "CIDR range for VPC Access Connector (must be /28)"
  type        = string
  default     = "10.8.0.0/28"
  validation {
    condition     = can(regex("/28$", var.connector_cidr))
    error_message = "Connector CIDR must be a /28 range"
  }
}

variable "connector_min_instances" {
  description = "Minimum number of VPC connector instances"
  type        = number
  default     = 2
}

variable "connector_max_instances" {
  description = "Maximum number of VPC connector instances"
  type        = number
  default     = 3
}

variable "connector_machine_type" {
  description = "Machine type for VPC connector"
  type        = string
  default     = "f1-micro"
  validation {
    condition     = contains(["f1-micro", "e2-micro", "e2-standard-4"], var.connector_machine_type)
    error_message = "Machine type must be one of: f1-micro (dev/staging), e2-micro, e2-standard-4 (production)"
  }
}

variable "enable_cloud_nat" {
  description = "Enable Cloud NAT for egress to internet (adds ~$32/month cost)"
  type        = bool
  default     = false
}

variable "labels" {
  description = "Labels to apply to all resources"
  type        = map(string)
  default     = {}
}
