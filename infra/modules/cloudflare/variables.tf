# Cloudflare Module Variables

variable "domain" {
  description = "The domain name for Cloudflare configuration"
  type        = string
  default     = "adyela.care"
}

variable "load_balancer_ip" {
  description = "The IP address of the GCP Load Balancer"
  type        = string
}

variable "environment" {
  description = "Environment name (staging, production)"
  type        = string
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
}

variable "labels" {
  description = "Labels to apply to resources"
  type        = map(string)
  default     = {}
}
