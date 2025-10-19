# Artifact Registry Module Outputs

output "repository_id" {
  description = "The ID of the created repository"
  value       = google_artifact_registry_repository.repository.repository_id
}

output "repository_name" {
  description = "The full name of the repository"
  value       = google_artifact_registry_repository.repository.name
}

output "repository_location" {
  description = "The location of the repository"
  value       = google_artifact_registry_repository.repository.location
}

output "repository_url" {
  description = "The URL to use when pulling/pushing images"
  value       = "${google_artifact_registry_repository.repository.location}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.repository.repository_id}"
}

output "repository_format" {
  description = "The format of the repository"
  value       = google_artifact_registry_repository.repository.format
}

output "cicd_service_account_email" {
  description = "Email of the CI/CD service account (if created)"
  value       = var.create_cicd_service_account ? google_service_account.cicd[0].email : null
}

output "cicd_service_account_id" {
  description = "ID of the CI/CD service account (if created)"
  value       = var.create_cicd_service_account ? google_service_account.cicd[0].account_id : null
}

output "cicd_service_account_unique_id" {
  description = "Unique ID of the CI/CD service account (if created)"
  value       = var.create_cicd_service_account ? google_service_account.cicd[0].unique_id : null
}
