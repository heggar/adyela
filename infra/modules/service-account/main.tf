# Service Account Module - HIPAA-Compliant
# Cost: $0.00/month (FREE)
# Required for: Secure Cloud Run deployments, Secret Manager access

terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.0"
    }
  }
}

# Service Account for HIPAA-compliant deployments
resource "google_service_account" "hipaa" {
  account_id   = "${var.project_name}-${var.environment}-hipaa"
  display_name = "${title(var.project_name)} ${title(var.environment)} HIPAA Service Account"
  description  = "Dedicated service account for HIPAA-compliant ${var.environment} deployments"
}

# IAM bindings for Cloud Run Admin
resource "google_project_iam_member" "run_admin" {
  project = var.project_id
  role    = "roles/run.admin"
  member  = "serviceAccount:${google_service_account.hipaa.email}"
}

# IAM bindings for Secret Manager Secret Accessor
resource "google_project_iam_member" "secret_accessor" {
  project = var.project_id
  role    = "roles/secretmanager.secretAccessor"
  member  = "serviceAccount:${google_service_account.hipaa.email}"
}

# IAM bindings for Cloud SQL Client
resource "google_project_iam_member" "cloudsql_client" {
  project = var.project_id
  role    = "roles/cloudsql.client"
  member  = "serviceAccount:${google_service_account.hipaa.email}"
}

# IAM bindings for Firestore User
resource "google_project_iam_member" "datastore_user" {
  project = var.project_id
  role    = "roles/datastore.user"
  member  = "serviceAccount:${google_service_account.hipaa.email}"
}

# IAM bindings for Storage Object Viewer
resource "google_project_iam_member" "storage_object_viewer" {
  project = var.project_id
  role    = "roles/storage.objectViewer"
  member  = "serviceAccount:${google_service_account.hipaa.email}"
}

# IAM bindings for Logging Writer (HIPAA audit logs)
resource "google_project_iam_member" "logging_writer" {
  project = var.project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.hipaa.email}"
}

# IAM bindings for Service Account User (for GitHub Actions)
resource "google_project_iam_member" "service_account_user" {
  project = var.project_id
  role    = "roles/iam.serviceAccountUser"
  member  = "serviceAccount:${google_service_account.hipaa.email}"
}

# IAM bindings for Artifact Registry Reader (for pulling images)
resource "google_project_iam_member" "artifact_registry_reader" {
  project = var.project_id
  role    = "roles/artifactregistry.reader"
  member  = "serviceAccount:${google_service_account.hipaa.email}"
}
