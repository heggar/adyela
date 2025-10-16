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
      min_instance_count = var.min_instances
      max_instance_count = var.max_instances
    }

    containers {
      image = var.api_image

      ports {
        container_port = 8000
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

      env {
        name  = "CORS_ORIGINS"
        value = "https://staging.adyela.care,https://adyela-staging.firebaseapp.com,https://adyela-staging.web.app"
      }

      # HIPAA Secrets
      dynamic "env" {
        for_each = var.hipaa_secrets
        content {
          name = env.key
          value_source {
            secret_key_ref {
              secret  = env.value
              version = "1"
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
      "run.googleapis.com/ingress" = "internal-and-cloud-load-balancing"
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
      min_instance_count = var.min_instances
      max_instance_count = var.max_instances
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

      # API Backend URL
      env {
        name  = "VITE_API_URL"
        value = var.api_url
      }

      # Firebase Configuration
      env {
        name  = "VITE_FIREBASE_PROJECT_ID"
        value = var.project_id
      }

      env {
        name  = "VITE_FIREBASE_AUTH_DOMAIN"
        value = "${var.project_id}.firebaseapp.com"
      }

      env {
        name  = "VITE_FIREBASE_STORAGE_BUCKET"
        value = "${var.project_id}.appspot.com"
      }

      # Firebase secrets from Secret Manager
      env {
        name = "VITE_FIREBASE_API_KEY"
        value_source {
          secret_key_ref {
            secret  = "firebase-web-api-key"
            version = "latest"
          }
        }
      }

      env {
        name = "VITE_FIREBASE_MESSAGING_SENDER_ID"
        value_source {
          secret_key_ref {
            secret  = "firebase-messaging-sender-id"
            version = "latest"
          }
        }
      }

      env {
        name = "VITE_FIREBASE_APP_ID"
        value_source {
          secret_key_ref {
            secret  = "firebase-web-app-id"
            version = "latest"
          }
        }
      }

      # Jitsi Configuration
      env {
        name  = "VITE_JITSI_DOMAIN"
        value = "meet.jit.si"
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

# ================================================================================
# IAM Bindings - Public Access via Load Balancer
# ================================================================================

# Allow public access to API service through Load Balancer
resource "google_cloud_run_service_iam_member" "api_public_access" {
  service  = google_cloud_run_v2_service.api.name
  location = google_cloud_run_v2_service.api.location
  role     = "roles/run.invoker"
  member   = "allUsers"
}

# Allow public access to Web service through Load Balancer
resource "google_cloud_run_service_iam_member" "web_public_access" {
  service  = google_cloud_run_v2_service.web.name
  location = google_cloud_run_v2_service.web.location
  role     = "roles/run.invoker"
  member   = "allUsers"
}
