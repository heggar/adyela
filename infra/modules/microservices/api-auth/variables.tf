variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "region" {
  description = "GCP region for Cloud Run service"
  type        = string
  default     = "us-central1"
}

variable "service_name" {
  description = "Name of the Cloud Run service"
  type        = string
  default     = "api-auth"
}

variable "container_image" {
  description = "Container image URL (e.g., gcr.io/project/api-auth:latest)"
  type        = string
}

variable "container_port" {
  description = "Port on which the container listens"
  type        = number
  default     = 8000
}

variable "cpu_limit" {
  description = "CPU limit (e.g., '1' for 1 vCPU)"
  type        = string
  default     = "1"
}

variable "memory_limit" {
  description = "Memory limit (e.g., '512Mi')"
  type        = string
  default     = "512Mi"
}

variable "cpu_always_allocated" {
  description = "Whether CPU is always allocated (false = scale-to-zero)"
  type        = bool
  default     = false
}

variable "min_instances" {
  description = "Minimum number of instances (0 for scale-to-zero)"
  type        = number
  default     = 0
}

variable "max_instances" {
  description = "Maximum number of instances"
  type        = number
  default     = 10
}

variable "timeout_seconds" {
  description = "Request timeout in seconds"
  type        = number
  default     = 60
}

variable "health_check_path" {
  description = "Path for health check endpoint"
  type        = string
  default     = "/health"
}

variable "service_account_email" {
  description = "Service account email for the Cloud Run service"
  type        = string
}

variable "environment_variables" {
  description = "Environment variables for the container"
  type        = map(string)
  default     = {}
}

variable "secret_environment_variables" {
  description = "Secret environment variables from Secret Manager"
  type = map(object({
    secret  = string
    version = string
  }))
  default = {}
}

variable "invoker_members" {
  description = "List of members allowed to invoke the service (e.g., serviceAccount:...)"
  type        = list(string)
  default     = []
}

variable "allow_unauthenticated" {
  description = "Allow unauthenticated access (public endpoints)"
  type        = bool
  default     = false
}

variable "environment" {
  description = "Environment name (staging, production)"
  type        = string
}

variable "labels" {
  description = "Additional labels for cost attribution"
  type        = map(string)
  default     = {}
}
