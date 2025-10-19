# Cloud Build Module
# Manages CI/CD pipelines for automated container builds and deployments

terraform {
  required_version = ">= 1.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.0"
    }
  }
}

# Cloud Build Trigger for automated builds
resource "google_cloudbuild_trigger" "trigger" {
  project     = var.project_id
  name        = var.trigger_name
  description = var.description
  location    = var.location

  # GitHub integration
  dynamic "github" {
    for_each = var.github_config != null ? [var.github_config] : []
    content {
      owner = github.value.owner
      name  = github.value.repo_name

      dynamic "push" {
        for_each = github.value.push_config != null ? [github.value.push_config] : []
        content {
          branch       = lookup(push.value, "branch", null)
          tag          = lookup(push.value, "tag", null)
          invert_regex = lookup(push.value, "invert_regex", false)
        }
      }

      dynamic "pull_request" {
        for_each = github.value.pull_request_config != null ? [github.value.pull_request_config] : []
        content {
          branch          = pull_request.value.branch
          comment_control = lookup(pull_request.value, "comment_control", "COMMENTS_ENABLED")
          invert_regex    = lookup(pull_request.value, "invert_regex", false)
        }
      }
    }
  }

  # Build configuration
  dynamic "build" {
    for_each = var.inline_build_config != null ? [var.inline_build_config] : []
    content {
      # Build steps
      dynamic "step" {
        for_each = build.value.steps
        content {
          name       = step.value.name
          args       = lookup(step.value, "args", [])
          env        = lookup(step.value, "env", [])
          id         = lookup(step.value, "id", null)
          wait_for   = lookup(step.value, "wait_for", [])
          entrypoint = lookup(step.value, "entrypoint", null)
          dir        = lookup(step.value, "dir", null)
          secret_env = lookup(step.value, "secret_env", [])
        }
      }

      # Substitutions (variables)
      substitutions = lookup(build.value, "substitutions", {})

      # Timeout
      timeout = lookup(build.value, "timeout", "600s")

      # Images to push
      images = lookup(build.value, "images", [])

      # Artifacts
      dynamic "artifacts" {
        for_each = lookup(build.value, "artifacts", null) != null ? [build.value.artifacts] : []
        content {
          images = lookup(artifacts.value, "images", [])

          dynamic "objects" {
            for_each = lookup(artifacts.value, "objects", null) != null ? [artifacts.value.objects] : []
            content {
              location = objects.value.location
              paths    = objects.value.paths
            }
          }
        }
      }

      # Build options
      dynamic "options" {
        for_each = lookup(build.value, "options", null) != null ? [build.value.options] : []
        content {
          machine_type            = lookup(options.value, "machine_type", "E2_HIGHCPU_8")
          disk_size_gb            = lookup(options.value, "disk_size_gb", 100)
          substitution_option     = lookup(options.value, "substitution_option", "ALLOW_LOOSE")
          dynamic_substitutions   = lookup(options.value, "dynamic_substitutions", false)
          log_streaming_option    = lookup(options.value, "log_streaming_option", "STREAM_ON")
          logging                 = lookup(options.value, "logging", "CLOUD_LOGGING_ONLY")
          requested_verify_option = lookup(options.value, "requested_verify_option", "NOT_VERIFIED")
        }
      }

      # Service account
      service_account = var.service_account_email != null ? var.service_account_email : null
    }
  }

  # Build from cloudbuild.yaml file
  filename = var.build_config_file

  # Substitutions available for all builds
  substitutions = var.substitutions

  # Included/ignored files
  included_files = var.included_files
  ignored_files  = var.ignored_files

  # Approval config
  dynamic "approval_config" {
    for_each = var.require_approval ? [1] : []
    content {
      approval_required = true
    }
  }

  # Service account
  service_account = var.service_account_email

  # Tags
  tags = concat(
    [var.environment, "managed-by-terraform"],
    var.tags
  )

  # Disabled state
  disabled = var.disabled
}

# Service Account for Cloud Build (optional)
resource "google_service_account" "cloudbuild" {
  count = var.create_service_account ? 1 : 0

  project      = var.project_id
  account_id   = "${var.trigger_name}-builder"
  display_name = "Cloud Build Service Account for ${var.trigger_name}"
  description  = "Service account used by Cloud Build trigger: ${var.trigger_name}"
}

# IAM: Grant Cloud Build permissions to push to Artifact Registry
resource "google_project_iam_member" "artifact_registry_writer" {
  count = var.create_service_account && var.grant_artifact_registry_access ? 1 : 0

  project = var.project_id
  role    = "roles/artifactregistry.writer"
  member  = "serviceAccount:${google_service_account.cloudbuild[0].email}"
}

# IAM: Grant Cloud Build permissions to deploy to Cloud Run
resource "google_project_iam_member" "cloud_run_admin" {
  count = var.create_service_account && var.grant_cloud_run_access ? 1 : 0

  project = var.project_id
  role    = "roles/run.admin"
  member  = "serviceAccount:${google_service_account.cloudbuild[0].email}"
}

# IAM: Grant Cloud Build permissions to read secrets
resource "google_project_iam_member" "secret_accessor" {
  count = var.create_service_account && var.grant_secret_access ? 1 : 0

  project = var.project_id
  role    = "roles/secretmanager.secretAccessor"
  member  = "serviceAccount:${google_service_account.cloudbuild[0].email}"
}

# IAM: Grant Cloud Build permissions to act as service account
resource "google_service_account_iam_member" "act_as" {
  count = var.create_service_account && var.cloud_run_service_account != null ? 1 : 0

  service_account_id = var.cloud_run_service_account
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${google_service_account.cloudbuild[0].email}"
}

# IAM: Custom roles for specific resources
resource "google_project_iam_member" "custom_roles" {
  for_each = var.create_service_account ? var.custom_roles : {}

  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.cloudbuild[0].email}"
}
