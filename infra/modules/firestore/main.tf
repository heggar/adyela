# Firestore Database Module
# Manages Firestore databases, indexes, and security rules

terraform {
  required_version = ">= 1.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.0"
    }
  }
}

# Firestore Database
resource "google_firestore_database" "database" {
  project     = var.project_id
  name        = var.database_name
  location_id = var.location

  # Database type (FIRESTORE_NATIVE or DATASTORE_MODE)
  type = var.database_type

  # Concurrency mode (OPTIMISTIC or PESSIMISTIC)
  concurrency_mode = var.concurrency_mode

  # App Engine integration mode (ENABLED or DISABLED)
  app_engine_integration_mode = var.app_engine_integration_mode

  # Point-in-time recovery (PITR)
  point_in_time_recovery_enablement = var.enable_pitr ? "POINT_IN_TIME_RECOVERY_ENABLED" : "POINT_IN_TIME_RECOVERY_DISABLED"

  # Delete protection
  delete_protection_state = var.delete_protection ? "DELETE_PROTECTION_ENABLED" : "DELETE_PROTECTION_DISABLED"

  # Deletion policy (DELETE or ABANDON)
  deletion_policy = var.force_destroy ? "DELETE" : "ABANDON"
}

# Firestore Indexes for query optimization
resource "google_firestore_index" "indexes" {
  for_each = { for idx in var.indexes : idx.name => idx }

  project    = var.project_id
  database   = google_firestore_database.database.name
  collection = each.value.collection

  # Query scope (COLLECTION or COLLECTION_GROUP)
  query_scope = lookup(each.value, "query_scope", "COLLECTION")

  # Index fields
  dynamic "fields" {
    for_each = each.value.fields
    content {
      field_path   = fields.value.field_path
      order        = lookup(fields.value, "order", null)
      array_config = lookup(fields.value, "array_config", null)
    }
  }
}

# Security Rules Deployment (from local file)
resource "google_firebaserules_ruleset" "firestore_rules" {
  count = var.security_rules_file != null ? 1 : 0

  project = var.project_id

  source {
    files {
      name    = "firestore.rules"
      content = file(var.security_rules_file)
    }
  }
}

resource "google_firebaserules_release" "firestore_rules_release" {
  count = var.security_rules_file != null ? 1 : 0

  project      = var.project_id
  name         = "cloud.firestore/${google_firestore_database.database.name}"
  ruleset_name = google_firebaserules_ruleset.firestore_rules[0].name

  depends_on = [google_firebaserules_ruleset.firestore_rules]

  lifecycle {
    replace_triggered_by = [
      google_firebaserules_ruleset.firestore_rules[0].id
    ]
  }
}

# Backup Schedule (Daily backups with retention)
resource "google_firestore_backup_schedule" "daily_backup" {
  count = var.enable_backups ? 1 : 0

  project  = var.project_id
  database = google_firestore_database.database.name

  # Daily backups
  daily_recurrence {}

  # Retention period
  retention = var.backup_retention_days != null ? "${var.backup_retention_days * 86400}s" : "604800s" # Default: 7 days
}

# IAM Bindings for Firestore access
resource "google_project_iam_member" "firestore_users" {
  for_each = toset(var.firestore_users)

  project = var.project_id
  role    = "roles/datastore.user"
  member  = each.value
}

resource "google_project_iam_member" "firestore_viewers" {
  for_each = toset(var.firestore_viewers)

  project = var.project_id
  role    = "roles/datastore.viewer"
  member  = each.value
}

resource "google_project_iam_member" "firestore_owners" {
  for_each = toset(var.firestore_owners)

  project = var.project_id
  role    = "roles/datastore.owner"
  member  = each.value
}

# Import/Export bucket (for data migration and backups)
resource "google_storage_bucket" "firestore_exports" {
  count = var.create_export_bucket ? 1 : 0

  project  = var.project_id
  name     = "${var.project_id}-firestore-exports"
  location = var.location

  storage_class = "NEARLINE" # Cost-optimized for infrequent access

  # Lifecycle: Delete exports after 30 days
  lifecycle_rule {
    action {
      type = "Delete"
    }
    condition {
      age = 30
    }
  }

  # Uniform bucket-level access
  uniform_bucket_level_access = true

  labels = merge(
    var.labels,
    {
      purpose    = "firestore-export"
      managed_by = "terraform"
    }
  )
}

# Grant Firestore service account access to export bucket
resource "google_storage_bucket_iam_member" "firestore_export_access" {
  count = var.create_export_bucket ? 1 : 0

  bucket = google_storage_bucket.firestore_exports[0].name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:service-${data.google_project.project.number}@gcp-sa-firestore.iam.gserviceaccount.com"
}

# Data source for project number
data "google_project" "project" {
  project_id = var.project_id
}
