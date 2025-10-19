# Common Labels Module Outputs

output "labels" {
  description = "Standard labels to apply to all resources"
  value       = local.sanitized_labels
}

output "tags" {
  description = "Standard tags to apply to resources that support tags"
  value       = local.common_tags
}

output "compute_labels" {
  description = "Labels for compute resources (Cloud Run, GCE, GKE)"
  value       = local.compute_labels
}

output "storage_labels" {
  description = "Labels for storage resources (Cloud Storage, Firestore, Cloud SQL)"
  value       = local.storage_labels
}

output "networking_labels" {
  description = "Labels for networking resources (VPC, Load Balancers)"
  value       = local.networking_labels
}

output "security_labels" {
  description = "Labels for security resources (Secret Manager, KMS)"
  value       = local.security_labels
}

output "cicd_labels" {
  description = "Labels for CI/CD resources (Cloud Build, Artifact Registry)"
  value       = local.cicd_labels
}

output "monitoring_labels" {
  description = "Labels for monitoring resources (Cloud Monitoring, Logging)"
  value       = local.monitoring_labels
}

output "environment" {
  description = "Environment name"
  value       = var.environment
}

output "project_name" {
  description = "Project name"
  value       = var.project_name
}

output "team" {
  description = "Team name"
  value       = var.team
}
