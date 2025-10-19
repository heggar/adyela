# Cloud SQL PostgreSQL Module Outputs

output "instance_name" {
  description = "Name of the Cloud SQL instance"
  value       = google_sql_database_instance.instance.name
}

output "instance_connection_name" {
  description = "Connection name for Cloud SQL Proxy"
  value       = google_sql_database_instance.instance.connection_name
}

output "instance_self_link" {
  description = "Self link of the instance"
  value       = google_sql_database_instance.instance.self_link
}

output "instance_ip_address" {
  description = "IP address of the instance"
  value = {
    public  = var.enable_public_ip ? google_sql_database_instance.instance.public_ip_address : null
    private = var.private_network != null ? google_sql_database_instance.instance.private_ip_address : null
  }
}

output "database_version" {
  description = "PostgreSQL version"
  value       = google_sql_database_instance.instance.database_version
}

output "region" {
  description = "Region of the instance"
  value       = google_sql_database_instance.instance.region
}

output "high_availability" {
  description = "High availability status"
  value       = var.high_availability
}

output "databases" {
  description = "List of created databases"
  value       = [for db in google_sql_database.databases : db.name]
}

output "admin_user" {
  description = "Admin user name"
  value       = var.create_admin_user ? google_sql_user.admin[0].name : null
}

output "admin_password_secret" {
  description = "Secret Manager secret containing admin password"
  value       = var.create_admin_user && var.store_password_in_secret_manager ? google_secret_manager_secret.admin_password[0].id : null
}

output "admin_password" {
  description = "Admin password (sensitive - only use for initial setup)"
  value       = var.create_admin_user ? random_password.admin_password[0].result : null
  sensitive   = true
}

output "read_replica_connection_names" {
  description = "Connection names for read replicas"
  value       = { for k, v in google_sql_database_instance.read_replicas : k => v.connection_name }
}

output "pitr_enabled" {
  description = "Point-in-Time Recovery status"
  value       = var.enable_pitr
}

output "backups_enabled" {
  description = "Automated backup status"
  value       = var.enable_backups
}

output "connection_string" {
  description = "PostgreSQL connection string (use with caution)"
  value       = var.create_admin_user ? "postgresql://${google_sql_user.admin[0].name}:${random_password.admin_password[0].result}@${google_sql_database_instance.instance.private_ip_address}:5432/${length(var.databases) > 0 ? var.databases[0] : "postgres"}" : null
  sensitive   = true
}
