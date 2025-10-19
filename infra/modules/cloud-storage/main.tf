# Cloud Storage Bucket Module
# Manages GCS buckets for file storage, backups, and static assets

terraform {
  required_version = ">= 1.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.0"
    }
  }
}

# Cloud Storage Bucket
resource "google_storage_bucket" "bucket" {
  project  = var.project_id
  name     = var.bucket_name
  location = var.location

  # Storage class (STANDARD, NEARLINE, COLDLINE, ARCHIVE)
  storage_class = var.storage_class

  # Uniform bucket-level access (recommended for security)
  uniform_bucket_level_access = var.uniform_bucket_level_access

  # Public access prevention
  public_access_prevention = var.public_access_prevention

  # Versioning (keep historical versions of objects)
  versioning {
    enabled = var.versioning_enabled
  }

  # Lifecycle rules for cost optimization
  dynamic "lifecycle_rule" {
    for_each = var.lifecycle_rules
    content {
      action {
        type          = lifecycle_rule.value.action.type
        storage_class = lookup(lifecycle_rule.value.action, "storage_class", null)
      }

      condition {
        age                        = lookup(lifecycle_rule.value.condition, "age", null)
        created_before             = lookup(lifecycle_rule.value.condition, "created_before", null)
        with_state                 = lookup(lifecycle_rule.value.condition, "with_state", null)
        matches_storage_class      = lookup(lifecycle_rule.value.condition, "matches_storage_class", null)
        matches_prefix             = lookup(lifecycle_rule.value.condition, "matches_prefix", null)
        matches_suffix             = lookup(lifecycle_rule.value.condition, "matches_suffix", null)
        num_newer_versions         = lookup(lifecycle_rule.value.condition, "num_newer_versions", null)
        days_since_custom_time     = lookup(lifecycle_rule.value.condition, "days_since_custom_time", null)
        days_since_noncurrent_time = lookup(lifecycle_rule.value.condition, "days_since_noncurrent_time", null)
      }
    }
  }

  # CORS configuration for web access
  dynamic "cors" {
    for_each = var.cors_config != null ? [var.cors_config] : []
    content {
      origin          = cors.value.origin
      method          = cors.value.method
      response_header = lookup(cors.value, "response_header", ["*"])
      max_age_seconds = lookup(cors.value, "max_age_seconds", 3600)
    }
  }

  # Encryption configuration
  dynamic "encryption" {
    for_each = var.encryption_key != null ? [1] : []
    content {
      default_kms_key_name = var.encryption_key
    }
  }

  # Website configuration (for static website hosting)
  dynamic "website" {
    for_each = var.website_config != null ? [var.website_config] : []
    content {
      main_page_suffix = lookup(website.value, "main_page_suffix", "index.html")
      not_found_page   = lookup(website.value, "not_found_page", "404.html")
    }
  }

  # Logging configuration
  dynamic "logging" {
    for_each = var.logging_config != null ? [var.logging_config] : []
    content {
      log_bucket        = logging.value.log_bucket
      log_object_prefix = lookup(logging.value, "log_object_prefix", "")
    }
  }

  # Retention policy (for compliance)
  dynamic "retention_policy" {
    for_each = var.retention_policy != null ? [var.retention_policy] : []
    content {
      retention_period = retention_policy.value.retention_period
      is_locked        = lookup(retention_policy.value, "is_locked", false)
    }
  }

  # Autoclass (automatic storage class transitions)
  dynamic "autoclass" {
    for_each = var.enable_autoclass ? [1] : []
    content {
      enabled                = true
      terminal_storage_class = var.autoclass_terminal_storage_class
    }
  }

  # Labels for cost attribution and organization
  labels = merge(
    var.labels,
    {
      environment = var.environment
      managed-by  = "terraform"
    }
  )

  # Force destroy (allows Terraform to delete non-empty buckets)
  force_destroy = var.force_destroy
}

# IAM Policy Bindings for bucket access
resource "google_storage_bucket_iam_member" "readers" {
  for_each = toset(var.reader_members)

  bucket = google_storage_bucket.bucket.name
  role   = "roles/storage.objectViewer"
  member = each.value
}

resource "google_storage_bucket_iam_member" "writers" {
  for_each = toset(var.writer_members)

  bucket = google_storage_bucket.bucket.name
  role   = "roles/storage.objectCreator"
  member = each.value
}

resource "google_storage_bucket_iam_member" "admins" {
  for_each = toset(var.admin_members)

  bucket = google_storage_bucket.bucket.name
  role   = "roles/storage.objectAdmin"
  member = each.value
}

# Public access for static website hosting (optional)
resource "google_storage_bucket_iam_member" "public_access" {
  count = var.make_public ? 1 : 0

  bucket = google_storage_bucket.bucket.name
  role   = "roles/storage.objectViewer"
  member = "allUsers"
}

# Notification configuration for Cloud Functions/Pub/Sub (optional)
resource "google_storage_notification" "notification" {
  count = var.notification_config != null ? 1 : 0

  bucket         = google_storage_bucket.bucket.name
  payload_format = var.notification_config.payload_format
  topic          = var.notification_config.topic

  event_types        = lookup(var.notification_config, "event_types", ["OBJECT_FINALIZE"])
  custom_attributes  = lookup(var.notification_config, "custom_attributes", {})
  object_name_prefix = lookup(var.notification_config, "object_name_prefix", "")
  depends_on         = [google_storage_bucket.bucket]
}
