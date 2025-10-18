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
}

variable "container_image" {
  description = "Container image URL (e.g., gcr.io/project/service:tag)"
  type        = string
}

variable "container_port" {
  description = "Port on which the container listens"
  type        = number
  default     = 8000
}

# Resource Configuration
variable "cpu_limit" {
  description = "CPU limit (e.g., '1' for 1 vCPU, '2' for 2 vCPUs)"
  type        = string
  default     = "1"
}

variable "memory_limit" {
  description = "Memory limit (e.g., '512Mi', '1Gi', '2Gi')"
  type        = string
  default     = "512Mi"
}

variable "cpu_always_allocated" {
  description = "Whether CPU is always allocated (false = scale-to-zero, true = always on)"
  type        = bool
  default     = false
}

variable "cpu_throttling" {
  description = "Enable CPU throttling (true = cost optimized, false = performance optimized)"
  type        = bool
  default     = true
}

variable "startup_cpu_boost" {
  description = "Enable startup CPU boost for faster cold starts"
  type        = bool
  default     = true
}

variable "execution_environment" {
  description = "Execution environment (gen1 or gen2)"
  type        = string
  default     = "gen2"
}

# Scaling Configuration
variable "min_instances" {
  description = "Minimum number of instances (0 for scale-to-zero)"
  type        = number
  default     = 0
}

variable "max_instances" {
  description = "Maximum number of instances for autoscaling"
  type        = number
  default     = 10
}

variable "max_concurrent_requests" {
  description = "Maximum number of concurrent requests per instance"
  type        = number
  default     = 80
}

# Timeout & Health Checks
variable "timeout_seconds" {
  description = "Request timeout in seconds"
  type        = number
  default     = 60
}

variable "enable_health_checks" {
  description = "Enable startup and liveness probes"
  type        = bool
  default     = true
}

variable "health_check_path" {
  description = "Path for health check endpoint"
  type        = string
  default     = "/health"
}

# Service Account & Permissions
variable "create_service_account" {
  description = "Whether to create a service account for this service"
  type        = bool
  default     = true
}

variable "service_account_email" {
  description = "Service account email (if not creating one)"
  type        = string
  default     = ""
}

variable "service_account_roles" {
  description = "IAM roles to grant to the service account"
  type        = list(string)
  default = [
    "roles/cloudtrace.agent",
    "roles/logging.logWriter",
    "roles/monitoring.metricWriter",
  ]
}

# Environment Variables
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

# IAM & Access Control
variable "invoker_members" {
  description = "List of members allowed to invoke the service"
  type        = list(string)
  default     = []
}

variable "allow_unauthenticated" {
  description = "Allow unauthenticated access (public endpoints)"
  type        = bool
  default     = false
}

# Labels & Metadata
variable "environment" {
  description = "Environment name (staging, production)"
  type        = string
}

variable "tier" {
  description = "Service tier (free, pro, enterprise) for cost attribution"
  type        = string
  default     = "shared"
}

variable "labels" {
  description = "Additional labels for cost attribution and organization"
  type        = map(string)
  default     = {}
}
