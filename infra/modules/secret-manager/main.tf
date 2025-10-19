# Secret Manager Module
# Manages secrets with automatic rotation, replication, and access control

terraform {
  required_version = ">= 1.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

# Secrets
resource "google_secret_manager_secret" "secrets" {
  for_each = { for secret in var.secrets : secret.secret_id => secret }

  project   = var.project_id
  secret_id = each.value.secret_id

  labels = merge(
    var.labels,
    lookup(each.value, "labels", {})
  )

  # Replication policy
  replication {
    dynamic "auto" {
      for_each = lookup(each.value, "replication_policy", "automatic") == "automatic" ? [1] : []
      content {
        dynamic "customer_managed_encryption" {
          for_each = lookup(each.value, "kms_key_name", null) != null ? [1] : []
          content {
            kms_key_name = each.value.kms_key_name
          }
        }
      }
    }

    dynamic "user_managed" {
      for_each = lookup(each.value, "replication_policy", "automatic") == "user_managed" ? [1] : []
      content {
        dynamic "replicas" {
          for_each = lookup(each.value, "replicas", [])
          content {
            location = replicas.value.location

            dynamic "customer_managed_encryption" {
              for_each = lookup(replicas.value, "kms_key_name", null) != null ? [1] : []
              content {
                kms_key_name = replicas.value.kms_key_name
              }
            }
          }
        }
      }
    }
  }

  # Rotation configuration
  dynamic "rotation" {
    for_each = lookup(each.value, "rotation_period", null) != null ? [1] : []
    content {
      rotation_period    = each.value.rotation_period
      next_rotation_time = lookup(each.value, "next_rotation_time", null)
    }
  }

  # Topics for notifications
  dynamic "topics" {
    for_each = lookup(each.value, "topics", [])
    content {
      name = topics.value.name
    }
  }

  # Expiration
  dynamic "expire_time" {
    for_each = lookup(each.value, "expire_time", null) != null ? [1] : []
    content {
      expire_time = each.value.expire_time
    }
  }

  dynamic "ttl" {
    for_each = lookup(each.value, "ttl", null) != null ? [1] : []
    content {
      ttl = each.value.ttl
    }
  }

  # Version aliases
  dynamic "version_aliases" {
    for_each = lookup(each.value, "version_aliases", {})
    content {
      alias = version_aliases.key
    }
  }

  # Annotations
  annotations = lookup(each.value, "annotations", {})
}

# Secret Data (Versions)
resource "google_secret_manager_secret_version" "versions" {
  for_each = {
    for secret in var.secrets :
    secret.secret_id => secret
    if lookup(secret, "secret_data", null) != null
  }

  secret = google_secret_manager_secret.secrets[each.key].id

  # Secret data (plaintext will be encrypted by Secret Manager)
  secret_data = each.value.secret_data

  # Enabled by default
  enabled = lookup(each.value, "enabled", true)

  # Delete after this version
  deletion_policy = lookup(each.value, "deletion_policy", "DELETE")

  lifecycle {
    # Always ignore changes to secret_data (managed manually via console or scripts)
    # This prevents Terraform from overwriting secrets that are managed outside Terraform
    ignore_changes = [secret_data]
  }
}

# Random secrets (auto-generated)
resource "random_password" "auto_secrets" {
  for_each = {
    for secret in var.secrets :
    secret.secret_id => secret
    if lookup(secret, "generate_random", false)
  }

  length  = lookup(each.value, "random_length", 32)
  special = lookup(each.value, "random_special", true)
  upper   = lookup(each.value, "random_upper", true)
  lower   = lookup(each.value, "random_lower", true)
  numeric = lookup(each.value, "random_numeric", true)

  # Override allowed special characters
  override_special = lookup(each.value, "random_override_special", null)

  # Rotate based on rotation_period
  keepers = {
    rotation_time = lookup(each.value, "rotation_period", null) != null ? formatdate("YYYY-MM-DD", timestamp()) : "static"
  }
}

# Random secret versions
resource "google_secret_manager_secret_version" "random_versions" {
  for_each = {
    for secret in var.secrets :
    secret.secret_id => secret
    if lookup(secret, "generate_random", false)
  }

  secret      = google_secret_manager_secret.secrets[each.key].id
  secret_data = random_password.auto_secrets[each.key].result
  enabled     = true

  lifecycle {
    ignore_changes = [secret_data]
  }
}

# IAM Access Control per Secret
resource "google_secret_manager_secret_iam_member" "members" {
  for_each = {
    for binding in local.secret_iam_bindings :
    "${binding.secret_id}-${binding.member}-${binding.role}" => binding
  }

  project   = var.project_id
  secret_id = google_secret_manager_secret.secrets[each.value.secret_id].secret_id
  role      = each.value.role
  member    = each.value.member

  dynamic "condition" {
    for_each = lookup(each.value, "condition", null) != null ? [each.value.condition] : []
    content {
      title       = condition.value.title
      description = lookup(condition.value, "description", null)
      expression  = condition.value.expression
    }
  }
}

# IAM Policy for Secret (replaces all bindings)
resource "google_secret_manager_secret_iam_policy" "policies" {
  for_each = {
    for secret in var.secrets :
    secret.secret_id => secret
    if lookup(secret, "iam_policy_data", null) != null
  }

  project     = var.project_id
  secret_id   = google_secret_manager_secret.secrets[each.key].secret_id
  policy_data = each.value.iam_policy_data
}

# Locals for flattening IAM bindings
locals {
  secret_iam_bindings = flatten([
    for secret in var.secrets : [
      for binding in lookup(secret, "iam_bindings", []) : {
        secret_id = secret.secret_id
        member    = binding.member
        role      = binding.role
        condition = lookup(binding, "condition", null)
      }
    ]
  ])
}

# Pub/Sub Topics for Secret Change Notifications
resource "google_pubsub_topic" "secret_topics" {
  for_each = {
    for topic in var.notification_topics :
    topic.name => topic
  }

  project = var.project_id
  name    = each.value.name

  labels = var.labels

  # Message retention
  message_retention_duration = lookup(each.value, "message_retention_duration", "86600s")

  # Schema (optional)
  dynamic "schema_settings" {
    for_each = lookup(each.value, "schema_name", null) != null ? [1] : []
    content {
      schema   = each.value.schema_name
      encoding = lookup(each.value, "schema_encoding", "JSON")
    }
  }
}

# Grant Secret Manager permission to publish to topics
resource "google_pubsub_topic_iam_member" "secret_publisher" {
  for_each = {
    for topic in var.notification_topics :
    topic.name => topic
  }

  project = var.project_id
  topic   = google_pubsub_topic.secret_topics[each.key].name
  role    = "roles/pubsub.publisher"

  # Secret Manager service account
  member = "serviceAccount:service-${data.google_project.project.number}@gcp-sa-secretmanager.iam.gserviceaccount.com"
}

# Data source for project number
data "google_project" "project" {
  project_id = var.project_id
}
