# API Auth Microservice - Cloud Run Service
# Handles authentication, authorization, RBAC, and multi-tenancy enforcement

terraform {
  required_version = ">= 1.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.0"
    }
  }
}

resource "google_cloud_run_v2_service" "api_auth" {
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
        startup_cpu_boost = true
      }

      # Environment variables
      dynamic "env" {
        for_each = var.environment_variables
        content {
          name  = env.key
          value = env.value
        }
      }

      # Secret environment variables
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

      # Health check
      startup_probe {
        http_get {
          path = var.health_check_path
          port = var.container_port
        }
        initial_delay_seconds = 0
        timeout_seconds       = 1
        period_seconds        = 3
        failure_threshold     = 3
      }

      liveness_probe {
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

    # Scaling configuration - scale-to-zero for cost optimization
    scaling {
      min_instance_count = var.min_instances
      max_instance_count = var.max_instances
    }

    # Service account for service-to-service auth
    service_account = var.service_account_email

    # Timeout for requests
    timeout = "${var.timeout_seconds}s"

    # Labels for cost attribution
    labels = merge(
      var.labels,
      {
        service     = "api-auth"
        environment = var.environment
        managed-by  = "terraform"
      }
    )
  }

  traffic {
    type    = "TRAFFIC_TARGET_ALLOCATION_TYPE_LATEST"
    percent = 100
  }

  lifecycle {
    ignore_changes = [
      template[0].containers[0].image, # Allow CI/CD to update image
    ]
  }
}

# IAM policy for invoking the service
resource "google_cloud_run_v2_service_iam_member" "invoker" {
  for_each = toset(var.invoker_members)

  name     = google_cloud_run_v2_service.api_auth.name
  location = google_cloud_run_v2_service.api_auth.location
  project  = google_cloud_run_v2_service.api_auth.project
  role     = "roles/run.invoker"
  member   = each.value
}

# Allow unauthenticated access if specified (for public endpoints)
resource "google_cloud_run_v2_service_iam_member" "public_invoker" {
  count = var.allow_unauthenticated ? 1 : 0

  name     = google_cloud_run_v2_service.api_auth.name
  location = google_cloud_run_v2_service.api_auth.location
  project  = google_cloud_run_v2_service.api_auth.project
  role     = "roles/run.invoker"
  member   = "allUsers"
}
