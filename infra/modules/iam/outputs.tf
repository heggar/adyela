# IAM Module Outputs

# Service Accounts
output "service_accounts" {
  description = "Map of created service accounts with full details"
  value = {
    for sa_key, sa in google_service_account.service_accounts :
    sa_key => {
      name         = sa.name
      email        = sa.email
      unique_id    = sa.unique_id
      display_name = sa.display_name
      description  = sa.description
      disabled     = sa.disabled
    }
  }
}

output "service_account_emails" {
  description = "List of service account emails"
  value       = [for sa in google_service_account.service_accounts : sa.email]
}

output "service_account_names" {
  description = "List of service account resource names"
  value       = [for sa in google_service_account.service_accounts : sa.name]
}

output "service_account_unique_ids" {
  description = "Map of service account IDs to unique IDs"
  value       = { for sa_key, sa in google_service_account.service_accounts : sa_key => sa.unique_id }
}

# Service Account Keys (if created)
output "service_account_keys" {
  description = "Map of service account private keys (SENSITIVE - handle with care)"
  value = {
    for sa_key, key in google_service_account_key.keys :
    sa_key => {
      name          = key.name
      public_key    = key.public_key
      private_key   = key.private_key # Base64 encoded JSON key
      valid_after   = key.valid_after
      valid_before  = key.valid_before
      key_algorithm = key.key_algorithm
    }
  }
  sensitive = true
}

output "service_account_key_ids" {
  description = "Map of service account key IDs (non-sensitive)"
  value       = { for sa_key, key in google_service_account_key.keys : sa_key => key.name }
}

# Custom Roles
output "custom_roles" {
  description = "Map of created custom IAM roles"
  value = {
    for role_key, role in google_project_iam_custom_role.custom_roles :
    role_key => {
      id          = role.id
      name        = role.name
      title       = role.title
      description = role.description
      permissions = role.permissions
      stage       = role.stage
    }
  }
}

output "custom_role_ids" {
  description = "List of custom role IDs"
  value       = [for role in google_project_iam_custom_role.custom_roles : role.role_id]
}

output "org_custom_roles" {
  description = "Map of created organization-level custom IAM roles"
  value = {
    for role_key, role in google_organization_iam_custom_role.org_custom_roles :
    role_key => {
      id          = role.id
      name        = role.name
      title       = role.title
      description = role.description
      permissions = role.permissions
      stage       = role.stage
    }
  }
}

# IAM Bindings
output "project_iam_bindings_count" {
  description = "Number of project-level IAM bindings created"
  value       = length(google_project_iam_member.project_bindings) + length(google_project_iam_member.additional_members)
}

output "service_account_iam_bindings_count" {
  description = "Number of service account IAM bindings created"
  value       = length(google_service_account_iam_member.service_account_bindings)
}

output "workload_identity_bindings_count" {
  description = "Number of Workload Identity bindings created"
  value       = length(google_service_account_iam_member.workload_identity)
}

# Audit Logging
output "audit_log_config_enabled" {
  description = "Whether audit logging is enabled"
  value       = var.enable_audit_logs
}

output "audit_log_services" {
  description = "Services with audit logging enabled"
  value       = var.enable_audit_logs ? var.audit_log_services : []
}

# Helper Outputs for Cloud Run
output "cloud_run_service_account" {
  description = "Email of Cloud Run service account (if created)"
  value       = var.enable_cloud_run_sa ? google_service_account.service_accounts["cloud-run"].email : null
}

# Helper Outputs for Cloud Build
output "cloud_build_service_account" {
  description = "Email of Cloud Build service account (if created)"
  value       = var.enable_cloud_build_sa ? google_service_account.service_accounts["cloud-build"].email : null
}

# Helper Outputs for GitHub Actions
output "github_actions_service_account" {
  description = "Email of GitHub Actions service account (if created)"
  value       = var.enable_github_actions_sa ? google_service_account.service_accounts["github-actions"].email : null
}

# Summary
output "summary" {
  description = "Summary of IAM resources created"
  value = {
    service_accounts_created     = length(google_service_account.service_accounts)
    custom_roles_created         = length(google_project_iam_custom_role.custom_roles)
    org_custom_roles_created     = length(google_organization_iam_custom_role.org_custom_roles)
    project_iam_bindings         = length(google_project_iam_member.project_bindings) + length(google_project_iam_member.additional_members)
    service_account_iam_bindings = length(google_service_account_iam_member.service_account_bindings)
    workload_identity_bindings   = length(google_service_account_iam_member.workload_identity)
    service_account_keys_created = length(google_service_account_key.keys)
    audit_logging_enabled        = var.enable_audit_logs
  }
}
