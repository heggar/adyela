# ================================================================================
# Cloud Run Module - HIPAA-Compliant Services
# ================================================================================
#
# IMPORTANT: Image versions are managed by CI/CD, not Terraform
# 
# Terraform creates and configures the Cloud Run service infrastructure:
# - CPU, memory, scaling configuration
# - Environment variables and secrets
# - VPC connectivity and ingress rules
# - Service account permissions
#
# CI/CD (GitHub Actions) handles image deployments:
# - Builds Docker images with specific versions
# - Deploys directly to Cloud Run using gcloud
# - Updates the service without touching Terraform state
#
# Expected workflow:
# 1. Terraform applies infrastructure changes (networking, scaling, secrets)
# 2. CI/CD deploys new images independently
# 3. Terraform plan will show "image" differences - THIS IS EXPECTED AND SAFE
# 4. Only apply Terraform when infrastructure configuration changes
# ================================================================================

# Cloud Run API Service
resource "google_cloud_run_v2_service" "api" {
  name     = "${var.project_name}-api-${var.environment}"
  location = var.region
  project  = var.project_id

  template {
    service_account = var.service_account_email

    # Configuración de timeout optimizada
    timeout = "60s"  # Reducido de 300s (default) a 60s

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
          cpu    = "1"       # Mantener 1 vCPU (requerido para concurrencia > 1)
          memory = "512Mi"   # Mantener 512Mi (mínimo requerido con CPU = 1)
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
              version = "latest"
            }
          }
        }
      }
    }

    dynamic "vpc_access" {
      for_each = var.vpc_connector_name != null && var.vpc_connector_name != "" ? [1] : []
      content {
        connector = "projects/${var.project_id}/locations/${var.region}/connectors/${var.vpc_connector_name}"
        egress    = "PRIVATE_RANGES_ONLY"
      }
    }

    annotations = {
      "run.googleapis.com/ingress" = "internal-and-cloud-load-balancing"
    }

    labels = var.labels
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

    # Configuración de timeout optimizada
    timeout = "60s"  # Reducido de 300s (default) a 60s

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
          cpu    = "1"       # Mantener 1 vCPU (requerido para concurrencia > 1)
          memory = "512Mi"   # Mantener 512Mi (mínimo requerido con CPU = 1)
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

    dynamic "vpc_access" {
      for_each = var.vpc_connector_name != null && var.vpc_connector_name != "" ? [1] : []
      content {
        connector = "projects/${var.project_id}/locations/${var.region}/connectors/${var.vpc_connector_name}"
        egress    = "PRIVATE_RANGES_ONLY"
      }
    }

    annotations = {
      "run.googleapis.com/ingress" = "internal-and-cloud-load-balancing"
    }

    labels = var.labels
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


# Public access is required for Load Balancer routing
# Security is enforced via:
# - Ingress restriction: internal-and-cloud-load-balancing only
# - Cloud Armor WAF protection
# - SSL/TLS encryption
# - OAuth/Firebase authentication at application level
# checkov:skip=CKV_GCP_102:Public access required for Load Balancer. Security via Cloud Armor + ingress restriction.
resource "google_cloud_run_service_iam_member" "api_public_access" {
  service  = google_cloud_run_v2_service.api.name
  location = google_cloud_run_v2_service.api.location
  role     = "roles/run.invoker"
  member   = "allUsers"
}

# checkov:skip=CKV_GCP_102:Public access required for Load Balancer. Security via Cloud Armor + ingress restriction.
resource "google_cloud_run_service_iam_member" "web_public_access" {
  service  = google_cloud_run_v2_service.web.name
  location = google_cloud_run_v2_service.web.location
  role     = "roles/run.invoker"
  member   = "allUsers"
}
