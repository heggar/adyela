# Artifact Registry Module
# Manages Docker container repositories for microservices

terraform {
  required_version = ">= 1.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.0"
    }
  }
}

# Artifact Registry Repository
resource "google_artifact_registry_repository" "repository" {
  location      = var.location
  repository_id = var.repository_id
  description   = var.description
  format        = var.format
  project       = var.project_id

  # Labels for cost attribution and organization
  labels = merge(
    var.labels,
    {
      environment = var.environment
      managed-by  = "terraform"
      purpose     = "container-storage"
    }
  )

  # Cleanup policies to manage storage costs
  dynamic "cleanup_policies" {
    for_each = var.cleanup_policies
    content {
      id     = cleanup_policies.value.id
      action = cleanup_policies.value.action

      dynamic "condition" {
        for_each = cleanup_policies.value.condition != null ? [cleanup_policies.value.condition] : []
        content {
          tag_state             = lookup(condition.value, "tag_state", null)
          tag_prefixes          = lookup(condition.value, "tag_prefixes", null)
          older_than            = lookup(condition.value, "older_than", null)
          newer_than            = lookup(condition.value, "newer_than", null)
          package_name_prefixes = lookup(condition.value, "package_name_prefixes", null)
          version_name_prefixes = lookup(condition.value, "version_name_prefixes", null)
        }
      }

      dynamic "most_recent_versions" {
        for_each = cleanup_policies.value.most_recent_versions != null ? [cleanup_policies.value.most_recent_versions] : []
        content {
          keep_count            = lookup(most_recent_versions.value, "keep_count", null)
          package_name_prefixes = lookup(most_recent_versions.value, "package_name_prefixes", null)
        }
      }
    }
  }

  # Docker configuration for immutability and vulnerability scanning
  dynamic "docker_config" {
    for_each = var.format == "DOCKER" ? [1] : []
    content {
      immutable_tags = var.immutable_tags
    }
  }

  # Encryption configuration
  dynamic "kms_key_name" {
    for_each = var.kms_key_name != null ? [var.kms_key_name] : []
    content {
      kms_key_name = kms_key_name.value
    }
  }

  mode = var.mode
}

# IAM bindings for repository access
resource "google_artifact_registry_repository_iam_binding" "readers" {
  for_each = toset(var.reader_members)

  location   = google_artifact_registry_repository.repository.location
  repository = google_artifact_registry_repository.repository.name
  role       = "roles/artifactregistry.reader"
  members    = [each.value]
  project    = var.project_id
}

resource "google_artifact_registry_repository_iam_binding" "writers" {
  for_each = toset(var.writer_members)

  location   = google_artifact_registry_repository.repository.location
  repository = google_artifact_registry_repository.repository.name
  role       = "roles/artifactregistry.writer"
  members    = [each.value]
  project    = var.project_id
}

# Service account for CI/CD pipeline (optional)
resource "google_service_account" "cicd" {
  count = var.create_cicd_service_account ? 1 : 0

  account_id   = "${var.repository_id}-cicd"
  display_name = "CI/CD Service Account for ${var.repository_id}"
  description  = "Service account for pushing images to ${var.repository_id}"
  project      = var.project_id
}

# Grant writer permission to CI/CD service account
resource "google_artifact_registry_repository_iam_member" "cicd_writer" {
  count = var.create_cicd_service_account ? 1 : 0

  location   = google_artifact_registry_repository.repository.location
  repository = google_artifact_registry_repository.repository.name
  role       = "roles/artifactregistry.writer"
  member     = "serviceAccount:${google_service_account.cicd[0].email}"
  project    = var.project_id
}

# Grant storage admin for cleanup
resource "google_project_iam_member" "cicd_storage_admin" {
  count = var.create_cicd_service_account && var.grant_storage_admin ? 1 : 0

  project = var.project_id
  role    = "roles/storage.admin"
  member  = "serviceAccount:${google_service_account.cicd[0].email}"
}
