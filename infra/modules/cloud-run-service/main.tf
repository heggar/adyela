# Generic Cloud Run Service Module
# Reusable module for all microservices (api-auth, api-appointments, etc.)

terraform {
  required_version = ">= 1.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.0"
    }
  }
}

resource "google_cloud_run_v2_service" "service" {
  name     = var.service_name
  location = var.region
  project  = var.project_id

  template {
    containers {
      image = var.container_image

      # Resource limits optimized for FinOps
      resources {
        limits = {
          cpu    = var.cpu_limit
          memory = var.memory_limit
        }
        cpu_idle          = var.cpu_always_allocated
        startup_cpu_boost = var.startup_cpu_boost
      }

      # Environment variables
      dynamic "env" {
        for_each = var.environment_variables
        content {
          name  = env.key
          value = env.value
        }
      }

      # Secret environment variables from Secret Manager
      dynamic "env" {
        for_each = var.secret_environment_variables
        content {
          name = env.key
          value_source {
            secret_key_ref {
              secret  = env.value.secret
              version = env.value.version
            }
          }
        }
      }

      ports {
        container_port = var.container_port
        name           = "http1"
      }

      # Startup probe
      dynamic "startup_probe" {
        for_each = var.enable_health_checks ? [1] : []
        content {
          http_get {
            path = var.health_check_path
            port = var.container_port
          }
          initial_delay_seconds = 0
          timeout_seconds       = 1
          period_seconds        = 3
          failure_threshold     = 3
        }
      }

      # Liveness probe
      dynamic "liveness_probe" {
        for_each = var.enable_health_checks ? [1] : []
        content {
          http_get {
            path = var.health_check_path
            port = var.container_port
          }
          initial_delay_seconds = 0
          timeout_seconds       = 1
          period_seconds        = 10
          failure_threshold     = 3
        }
      }
    }

    # Scaling configuration - scale-to-zero for cost optimization
    scaling {
      min_instance_count = var.min_instances
      max_instance_count = var.max_instances
    }

    # Service account for service-to-service auth
    service_account = var.service_account_email

    # Timeout for requests
    timeout = "${var.timeout_seconds}s"

    # Max concurrent requests per instance
    max_instance_request_concurrency = var.max_concurrent_requests

    # Labels for cost attribution
    labels = merge(
      var.labels,
      {
        service     = var.service_name
        environment = var.environment
        managed-by  = "terraform"
        tier        = var.tier
      }
    )

    # Annotations for scaling behavior
    annotations = {
      "autoscaling.knative.dev/minScale"         = tostring(var.min_instances)
      "autoscaling.knative.dev/maxScale"         = tostring(var.max_instances)
      "run.googleapis.com/cpu-throttling"        = var.cpu_throttling ? "true" : "false"
      "run.googleapis.com/execution-environment" = var.execution_environment
    }
  }

  traffic {
    type    = "TRAFFIC_TARGET_ALLOCATION_TYPE_LATEST"
    percent = 100
  }

  lifecycle {
    ignore_changes = [
      template[0].containers[0].image, # Allow CI/CD to update image
      template[0].labels,              # Allow CI/CD to update labels
    ]
  }
}

# IAM policy for specific invokers
resource "google_cloud_run_v2_service_iam_member" "invokers" {
  for_each = toset(var.invoker_members)

  name     = google_cloud_run_v2_service.service.name
  location = google_cloud_run_v2_service.service.location
  project  = google_cloud_run_v2_service.service.project
  role     = "roles/run.invoker"
  member   = each.value
}

# Allow unauthenticated access if specified (for public endpoints)
resource "google_cloud_run_v2_service_iam_member" "public_invoker" {
  count = var.allow_unauthenticated ? 1 : 0

  name     = google_cloud_run_v2_service.service.name
  location = google_cloud_run_v2_service.service.location
  project  = google_cloud_run_v2_service.service.project
  role     = "roles/run.invoker"
  member   = "allUsers"
}

# Service account for the Cloud Run service
resource "google_service_account" "service" {
  count = var.create_service_account ? 1 : 0

  account_id   = "${var.service_name}-sa"
  display_name = "Service Account for ${var.service_name}"
  project      = var.project_id
}

# Grant necessary permissions to service account
resource "google_project_iam_member" "service_permissions" {
  for_each = var.create_service_account ? toset(var.service_account_roles) : []

  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.service[0].email}"
}
