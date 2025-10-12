# ================================================================================
# Cloud Run Module - HIPAA-Compliant Services
# ================================================================================

# Cloud Run API Service
resource "google_cloud_run_v2_service" "api" {
  name     = "${var.project_name}-api-${var.environment}"
  location = var.region
  project  = var.project_id

  template {
    service_account = var.service_account_email

    scaling {
      min_instance_count = 0
      max_instance_count = 2
    }

    containers {
      image = var.api_image

      ports {
        container_port = 8080
      }

      resources {
        limits = {
          cpu    = "1"
          memory = "512Mi"
        }
      }

      env {
        name  = "ENVIRONMENT"
        value = var.environment
      }

      env {
        name  = "VERSION"
        value = var.app_version
      }

      env {
        name  = "GCP_PROJECT_ID"
        value = var.project_id
      }

      env {
        name  = "HIPAA_COMPLIANCE"
        value = "true"
      }

      env {
        name  = "AUDIT_LOGGING"
        value = "true"
      }

      env {
        name  = "DATA_ENCRYPTION"
        value = "true"
      }

      # HIPAA Secrets
      dynamic "env" {
        for_each = var.hipaa_secrets
        content {
          name = env.key
          value_source {
            secret_key_ref {
              secret  = env.value
              version = "latest"
            }
          }
        }
      }
    }

    vpc_access {
      connector = "projects/${var.project_id}/locations/${var.region}/connectors/${var.vpc_connector_name}"
      egress    = "PRIVATE_RANGES_ONLY"
    }

    annotations = {
      "run.googleapis.com/ingress" = "internal"
    }
  }

  traffic {
    percent = 100
    type    = "TRAFFIC_TARGET_ALLOCATION_TYPE_LATEST"
  }

  labels = var.labels
}

# Cloud Run Web Service
resource "google_cloud_run_v2_service" "web" {
  name     = "${var.project_name}-web-${var.environment}"
  location = var.region
  project  = var.project_id

  template {
    service_account = var.service_account_email

    scaling {
      min_instance_count = 0
      max_instance_count = 2
    }

    containers {
      image = var.web_image

      ports {
        container_port = 8080
      }

      resources {
        limits = {
          cpu    = "1"
          memory = "512Mi"
        }
      }

      env {
        name  = "VITE_ENV"
        value = var.environment
      }

      env {
        name  = "VERSION"
        value = var.app_version
      }

      env {
        name  = "HIPAA_COMPLIANCE"
        value = "true"
      }

      env {
        name  = "AUDIT_LOGGING"
        value = "true"
      }
    }

    vpc_access {
      connector = "projects/${var.project_id}/locations/${var.region}/connectors/${var.vpc_connector_name}"
      egress    = "PRIVATE_RANGES_ONLY"
    }

    annotations = {
      "run.googleapis.com/ingress" = "internal-and-cloud-load-balancing"
    }
  }

  traffic {
    percent = 100
    type    = "TRAFFIC_TARGET_ALLOCATION_TYPE_LATEST"
  }

  labels = var.labels
}
