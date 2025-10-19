# IAM Module
# Manages service accounts, IAM roles, and least-privilege access control

terraform {
  required_version = ">= 1.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.0"
    }
  }
}

# Service Accounts
resource "google_service_account" "service_accounts" {
  for_each = { for sa in var.service_accounts : sa.account_id => sa }

  project      = var.project_id
  account_id   = each.value.account_id
  display_name = lookup(each.value, "display_name", each.value.account_id)
  description  = lookup(each.value, "description", "Managed by Terraform")
  disabled     = lookup(each.value, "disabled", false)
}

# Project-level IAM Bindings
resource "google_project_iam_member" "project_bindings" {
  for_each = {
    for binding in local.project_bindings :
    "${binding.member}-${binding.role}" => binding
  }

  project = var.project_id
  role    = each.value.role
  member  = each.value.member

  dynamic "condition" {
    for_each = lookup(each.value, "condition", null) != null ? [each.value.condition] : []
    content {
      title       = condition.value.title
      description = lookup(condition.value, "description", null)
      expression  = condition.value.expression
    }
  }
}

# Service Account IAM Bindings (for impersonation)
resource "google_service_account_iam_member" "service_account_bindings" {
  for_each = {
    for binding in local.service_account_bindings :
    "${binding.service_account_id}-${binding.member}-${binding.role}" => binding
  }

  service_account_id = google_service_account.service_accounts[each.value.service_account_id].name
  role               = each.value.role
  member             = each.value.member

  dynamic "condition" {
    for_each = lookup(each.value, "condition", null) != null ? [each.value.condition] : []
    content {
      title       = condition.value.title
      description = lookup(condition.value, "description", null)
      expression  = condition.value.expression
    }
  }
}

# Custom IAM Roles
resource "google_project_iam_custom_role" "custom_roles" {
  for_each = { for role in var.custom_roles : role.role_id => role }

  project     = var.project_id
  role_id     = each.value.role_id
  title       = each.value.title
  description = lookup(each.value, "description", "Custom role managed by Terraform")
  permissions = each.value.permissions
  stage       = lookup(each.value, "stage", "GA")
}

# Organization-level Custom Roles (if org_id provided)
resource "google_organization_iam_custom_role" "org_custom_roles" {
  for_each = var.org_id != null ? { for role in var.org_custom_roles : role.role_id => role } : {}

  org_id      = var.org_id
  role_id     = each.value.role_id
  title       = each.value.title
  description = lookup(each.value, "description", "Custom role managed by Terraform")
  permissions = each.value.permissions
  stage       = lookup(each.value, "stage", "GA")
}

# Service Account Keys (NOT RECOMMENDED - use Workload Identity instead)
resource "google_service_account_key" "keys" {
  for_each = var.create_keys ? { for sa in var.service_accounts : sa.account_id => sa if lookup(sa, "create_key", false) } : {}

  service_account_id = google_service_account.service_accounts[each.key].name
  key_algorithm      = lookup(each.value, "key_algorithm", "KEY_ALG_RSA_2048")
  public_key_type    = lookup(each.value, "public_key_type", "TYPE_X509_PEM_FILE")

  # Rotate keys every 90 days
  keepers = {
    rotation_time = timestamp()
  }
}

# Workload Identity Bindings (GKE/Cloud Run ’ Service Account)
resource "google_service_account_iam_member" "workload_identity" {
  for_each = {
    for binding in var.workload_identity_bindings :
    "${binding.service_account_id}-${binding.namespace}-${binding.k8s_service_account}" => binding
  }

  service_account_id = google_service_account.service_accounts[each.value.service_account_id].name
  role               = "roles/iam.workloadIdentityUser"
  member             = "serviceAccount:${var.project_id}.svc.id.goog[${each.value.namespace}/${each.value.k8s_service_account}]"
}

# IAM Policy for Service Accounts (replaces all bindings)
resource "google_service_account_iam_policy" "policies" {
  for_each = { for sa in var.service_accounts : sa.account_id => sa if lookup(sa, "iam_policy_data", null) != null }

  service_account_id = google_service_account.service_accounts[each.key].name
  policy_data        = each.value.iam_policy_data
}

# Locals for flattening nested structures
locals {
  # Flatten project-level bindings
  project_bindings = flatten([
    for sa_key, sa in var.service_accounts : [
      for role in lookup(sa, "project_roles", []) : {
        member = "serviceAccount:${google_service_account.service_accounts[sa_key].email}"
        role   = role
      }
    ]
  ])

  # Flatten service account impersonation bindings
  service_account_bindings = flatten([
    for sa_key, sa in var.service_accounts : [
      for binding in lookup(sa, "iam_bindings", []) : {
        service_account_id = sa_key
        member             = binding.member
        role               = binding.role
        condition          = lookup(binding, "condition", null)
      }
    ]
  ])

  # Flatten additional project IAM members
  additional_project_members = flatten([
    for member_key, member in var.project_iam_members : [
      for role in member.roles : {
        member    = member_key
        role      = role
        condition = lookup(member, "condition", null)
      }
    ]
  ])

  # Combine all project bindings
  all_project_bindings = concat(
    local.project_bindings,
    local.additional_project_members
  )
}

# Additional Project IAM Members (non-service accounts)
resource "google_project_iam_member" "additional_members" {
  for_each = {
    for binding in local.additional_project_members :
    "${binding.member}-${binding.role}" => binding
  }

  project = var.project_id
  role    = each.value.role
  member  = each.value.member

  dynamic "condition" {
    for_each = lookup(each.value, "condition", null) != null ? [each.value.condition] : []
    content {
      title       = condition.value.title
      description = lookup(condition.value, "description", null)
      expression  = condition.value.expression
    }
  }
}

# Service Account Email Outputs (for easy reference)
output "service_account_emails_map" {
  description = "Map of service account IDs to emails"
  value = {
    for sa_key, sa in google_service_account.service_accounts :
    sa_key => sa.email
  }
}

# IAM Audit Config (for Cloud Audit Logs)
resource "google_project_iam_audit_config" "audit_config" {
  for_each = var.enable_audit_logs ? toset(var.audit_log_services) : toset([])

  project = var.project_id
  service = each.value

  dynamic "audit_log_config" {
    for_each = var.audit_log_configs
    content {
      log_type         = audit_log_config.value.log_type
      exempted_members = lookup(audit_log_config.value, "exempted_members", [])
    }
  }
}
