# Secret Manager Module Outputs

# Secrets
output "secrets" {
  description = "Map of created secrets with full details"
  value = {
    for secret_key, secret in google_secret_manager_secret.secrets :
    secret_key => {
      id          = secret.id
      name        = secret.name
      secret_id   = secret.secret_id
      create_time = secret.create_time
      labels      = secret.labels
      replication = secret.replication
      rotation    = secret.rotation
    }
  }
}

output "secret_ids" {
  description = "List of secret IDs"
  value       = [for secret in google_secret_manager_secret.secrets : secret.secret_id]
}

output "secret_names" {
  description = "Map of secret IDs to full resource names"
  value       = { for secret_key, secret in google_secret_manager_secret.secrets : secret_key => secret.name }
}

# Secret Versions
output "secret_versions" {
  description = "Map of secret versions (non-sensitive metadata)"
  value = {
    for secret_key, version in google_secret_manager_secret_version.versions :
    secret_key => {
      id          = version.id
      name        = version.name
      create_time = version.create_time
      enabled     = version.enabled
      version     = version.version
    }
  }
}

output "secret_version_ids" {
  description = "Map of secret IDs to their latest version IDs"
  value = {
    for secret_key, version in google_secret_manager_secret_version.versions :
    secret_key => version.id
  }
}

# Random Secrets (generated values)
output "random_secret_values" {
  description = "Auto-generated secret values (SENSITIVE - handle with care)"
  value = {
    for secret_key, password in random_password.auto_secrets :
    secret_key => password.result
  }
  sensitive = true
}

output "random_secret_versions" {
  description = "Random secret versions (non-sensitive metadata)"
  value = {
    for secret_key, version in google_secret_manager_secret_version.random_versions :
    secret_key => {
      id          = version.id
      name        = version.name
      create_time = version.create_time
      enabled     = version.enabled
      version     = version.version
    }
  }
}

# IAM Bindings
output "secret_iam_bindings_count" {
  description = "Number of secret IAM bindings created"
  value       = length(google_secret_manager_secret_iam_member.members)
}

# Notification Topics
output "notification_topics" {
  description = "Map of Pub/Sub topics for secret change notifications"
  value = {
    for topic_key, topic in google_pubsub_topic.secret_topics :
    topic_key => {
      id   = topic.id
      name = topic.name
    }
  }
}

output "notification_topic_names" {
  description = "List of notification topic names"
  value       = [for topic in google_pubsub_topic.secret_topics : topic.name]
}

# Helper Outputs for Common Secrets
output "database_url_secret_name" {
  description = "Full resource name of database URL secret (if created)"
  value       = var.create_database_url_secret ? google_secret_manager_secret.secrets["database-url"].name : null
}

output "api_key_secret_name" {
  description = "Full resource name of API key secret (if created)"
  value       = var.create_api_key_secret ? google_secret_manager_secret.secrets["api-key"].name : null
}

output "jwt_secret_name" {
  description = "Full resource name of JWT secret (if created)"
  value       = var.create_jwt_secret ? google_secret_manager_secret.secrets["jwt-secret"].name : null
}

# Secret References for Cloud Run
output "secret_env_references" {
  description = "Map of secret environment variable references for Cloud Run"
  value = {
    for secret_key, secret in google_secret_manager_secret.secrets :
    secret_key => {
      name       = secret_key
      value_from = "projects/${var.project_id}/secrets/${secret.secret_id}/versions/latest"
    }
  }
}

# Summary
output "summary" {
  description = "Summary of Secret Manager resources created"
  value = {
    secrets_created             = length(google_secret_manager_secret.secrets)
    secret_versions_created     = length(google_secret_manager_secret_version.versions)
    random_secrets_generated    = length(random_password.auto_secrets)
    iam_bindings_created        = length(google_secret_manager_secret_iam_member.members)
    notification_topics_created = length(google_pubsub_topic.secret_topics)
  }
}

# Secret Access Instructions
output "access_instructions" {
  description = "Instructions for accessing secrets"
  value = {
    cli_example       = "gcloud secrets versions access latest --secret=SECRET_ID --project=${var.project_id}"
    terraform_example = "data.google_secret_manager_secret_version.example { secret = \"projects/${var.project_id}/secrets/SECRET_ID\" version = \"latest\" }"
    cloud_run_example = "env: [{name: \"DB_URL\", value_from { secret_key_ref { name: \"SECRET_ID\", version: \"latest\" }}}]"
  }
}
