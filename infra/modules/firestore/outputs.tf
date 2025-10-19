# Firestore Module Outputs

output "database_name" {
  description = "Name of the Firestore database"
  value       = google_firestore_database.database.name
}

output "database_id" {
  description = "ID of the Firestore database"
  value       = google_firestore_database.database.id
}

output "database_location" {
  description = "Location of the Firestore database"
  value       = google_firestore_database.database.location_id
}

output "database_type" {
  description = "Type of the Firestore database"
  value       = google_firestore_database.database.type
}

output "pitr_enabled" {
  description = "Whether Point-in-Time Recovery is enabled"
  value       = var.enable_pitr
}

output "export_bucket_name" {
  description = "Name of the Firestore export bucket (if created)"
  value       = var.create_export_bucket ? google_storage_bucket.firestore_exports[0].name : null
}

output "export_bucket_url" {
  description = "URL of the Firestore export bucket (if created)"
  value       = var.create_export_bucket ? google_storage_bucket.firestore_exports[0].url : null
}

output "security_rules_deployed" {
  description = "Whether security rules were deployed"
  value       = var.security_rules_file != null
}

output "indexes_created" {
  description = "Number of indexes created"
  value       = length(var.indexes)
}

output "backup_enabled" {
  description = "Whether automated backups are enabled"
  value       = var.enable_backups
}

output "backup_retention_days" {
  description = "Backup retention period in days"
  value       = var.backup_retention_days
}
