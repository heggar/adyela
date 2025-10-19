# Cloud SQL PostgreSQL Module
# Manages Cloud SQL PostgreSQL instances with HA, backups, and private networking

terraform {
  required_version = ">= 1.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

# Random suffix for instance name (Cloud SQL names cannot be reused for 1 week after deletion)
resource "random_id" "db_name_suffix" {
  byte_length = 4
}

# Cloud SQL PostgreSQL Instance
resource "google_sql_database_instance" "instance" {
  project          = var.project_id
  name             = "${var.instance_name}-${random_id.db_name_suffix.hex}"
  database_version = var.database_version
  region           = var.region

  # Deletion protection
  deletion_protection = var.deletion_protection

  settings {
    # Tier (machine type)
    tier              = var.tier
    availability_type = var.high_availability ? "REGIONAL" : "ZONAL"
    disk_type         = var.disk_type
    disk_size         = var.disk_size
    disk_autoresize   = var.disk_autoresize

    # Backup configuration
    backup_configuration {
      enabled                        = var.enable_backups
      start_time                     = var.backup_start_time
      point_in_time_recovery_enabled = var.enable_pitr
      transaction_log_retention_days = var.transaction_log_retention_days

      backup_retention_settings {
        retained_backups = var.backup_retention_count
        retention_unit   = "COUNT"
      }
    }

    # IP configuration
    ip_configuration {
      ipv4_enabled    = var.enable_public_ip
      private_network = var.private_network
      require_ssl     = var.require_ssl

      # Authorized networks (for public IP)
      dynamic "authorized_networks" {
        for_each = var.authorized_networks
        content {
          name  = authorized_networks.value.name
          value = authorized_networks.value.cidr
        }
      }
    }

    # Maintenance window
    maintenance_window {
      day          = var.maintenance_window.day
      hour         = var.maintenance_window.hour
      update_track = var.maintenance_window.update_track
    }

    # Database flags (PostgreSQL configuration)
    dynamic "database_flags" {
      for_each = var.database_flags
      content {
        name  = database_flags.value.name
        value = database_flags.value.value
      }
    }

    # Insights configuration
    insights_config {
      query_insights_enabled  = var.enable_query_insights
      query_string_length     = var.query_insights_query_string_length
      record_application_tags = var.query_insights_record_application_tags
      record_client_address   = var.query_insights_record_client_address
    }

    # Labels
    user_labels = merge(
      var.labels,
      {
        environment = var.environment
        managed-by  = "terraform"
      }
    )
  }

  # Prevent deletion of instance before backups are deleted
  lifecycle {
    prevent_destroy = false
  }
}

# Create databases
resource "google_sql_database" "databases" {
  for_each = toset(var.databases)

  project  = var.project_id
  name     = each.value
  instance = google_sql_database_instance.instance.name

  # Charset and collation
  charset   = var.database_charset
  collation = var.database_collation
}

# Generate random password for admin user
resource "random_password" "admin_password" {
  count = var.create_admin_user ? 1 : 0

  length  = 32
  special = true
}

# Create admin user
resource "google_sql_user" "admin" {
  count = var.create_admin_user ? 1 : 0

  project  = var.project_id
  name     = var.admin_user_name
  instance = google_sql_database_instance.instance.name
  password = random_password.admin_password[0].result
}

# Create additional users
resource "google_sql_user" "users" {
  for_each = var.additional_users

  project  = var.project_id
  name     = each.key
  instance = google_sql_database_instance.instance.name
  password = each.value.password
}

# Read replicas for load distribution
resource "google_sql_database_instance" "read_replicas" {
  for_each = var.read_replicas

  project              = var.project_id
  name                 = "${var.instance_name}-replica-${each.key}-${random_id.db_name_suffix.hex}"
  database_version     = var.database_version
  region               = each.value.region
  master_instance_name = google_sql_database_instance.instance.name

  replica_configuration {
    failover_target = lookup(each.value, "failover_target", false)
  }

  settings {
    tier              = lookup(each.value, "tier", var.tier)
    availability_type = "ZONAL" # Replicas are always zonal
    disk_type         = var.disk_type
    disk_size         = var.disk_size
    disk_autoresize   = var.disk_autoresize

    ip_configuration {
      ipv4_enabled    = var.enable_public_ip
      private_network = var.private_network
      require_ssl     = var.require_ssl
    }

    user_labels = merge(
      var.labels,
      {
        environment = var.environment
        managed-by  = "terraform"
        replica-of  = google_sql_database_instance.instance.name
      }
    )
  }

  deletion_protection = var.deletion_protection
}

# IAM bindings for Cloud SQL
resource "google_project_iam_member" "sql_client" {
  for_each = toset(var.sql_client_members)

  project = var.project_id
  role    = "roles/cloudsql.client"
  member  = each.value
}

resource "google_project_iam_member" "sql_admin" {
  for_each = toset(var.sql_admin_members)

  project = var.project_id
  role    = "roles/cloudsql.admin"
  member  = each.value
}

# Secret Manager integration (store admin password)
resource "google_secret_manager_secret" "admin_password" {
  count = var.create_admin_user && var.store_password_in_secret_manager ? 1 : 0

  project   = var.project_id
  secret_id = "${var.instance_name}-admin-password"

  replication {
    auto {}
  }

  labels = var.labels
}

resource "google_secret_manager_secret_version" "admin_password" {
  count = var.create_admin_user && var.store_password_in_secret_manager ? 1 : 0

  secret      = google_secret_manager_secret.admin_password[0].id
  secret_data = random_password.admin_password[0].result
}
