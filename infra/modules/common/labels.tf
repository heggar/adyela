# Common Labels and Tags Module
# Provides consistent labeling strategy across all GCP resources

terraform {
  required_version = ">= 1.0"
}

locals {
  # Standard labels applied to all resources
  # GCP label constraints:
  # - Keys and values must be lowercase
  # - Keys must start with lowercase letter
  # - Only lowercase letters, numbers, underscores, and hyphens allowed
  # - Maximum 63 characters per key/value

  # Core labels (always applied)
  core_labels = {
    # Infrastructure management
    managed_by = "terraform"
    terraform  = "true"

    # Environment
    environment = lower(var.environment)

    # Project/Product
    project = var.project_name
    product = var.product_name

    # Cost tracking
    cost_center = var.cost_center
    billing_id  = var.billing_id

    # Ownership
    team  = var.team
    owner = var.owner
  }

  # Optional labels (only applied if values provided)
  optional_labels = {
    for k, v in {
      # Application metadata
      application = var.application
      component   = var.component
      service     = var.service
      tier        = var.tier

      # Versioning
      version = var.app_version

      # Compliance
      compliance_required = var.compliance_required
      data_classification = var.data_classification
      hipaa_scope         = var.hipaa_scope

      # Operational
      backup_policy     = var.backup_policy
      disaster_recovery = var.disaster_recovery
      high_availability = var.high_availability

      # Contact
      contact_email = replace(var.contact_email, "@", "_at_") # Email must be sanitized

      # Custom labels
    } : k => v if v != null && v != ""
  }

  # Merged labels (core + optional + custom)
  all_labels = merge(
    local.core_labels,
    local.optional_labels,
    var.custom_labels
  )

  # Sanitized labels (enforce GCP constraints)
  sanitized_labels = {
    for k, v in local.all_labels :
    replace(lower(k), "/[^a-z0-9_-]/", "_") =>
    substr(replace(lower(v), "/[^a-z0-9_-]/", "_"), 0, 63)
  }

  # Common tags for resources that support tags (not all GCP resources)
  common_tags = concat(
    [
      var.environment,
      var.project_name,
      var.team,
      "managed-by-terraform"
    ],
    var.custom_tags
  )
}

# Preset label sets for common scenarios

# Labels for compute resources (Cloud Run, GCE, GKE)
locals {
  compute_labels = merge(
    local.sanitized_labels,
    {
      resource_type = "compute"
    }
  )
}

# Labels for storage resources (Cloud Storage, Firestore, Cloud SQL)
locals {
  storage_labels = merge(
    local.sanitized_labels,
    {
      resource_type = "storage"
    }
  )
}

# Labels for networking resources (VPC, Load Balancers, Cloud CDN)
locals {
  networking_labels = merge(
    local.sanitized_labels,
    {
      resource_type = "networking"
    }
  )
}

# Labels for security resources (Secret Manager, KMS, IAM)
locals {
  security_labels = merge(
    local.sanitized_labels,
    {
      resource_type = "security"
    }
  )
}

# Labels for CI/CD resources (Cloud Build, Artifact Registry)
locals {
  cicd_labels = merge(
    local.sanitized_labels,
    {
      resource_type = "cicd"
    }
  )
}

# Labels for monitoring resources (Cloud Monitoring, Logging)
locals {
  monitoring_labels = merge(
    local.sanitized_labels,
    {
      resource_type = "monitoring"
    }
  )
}
