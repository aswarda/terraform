# =====================================================================
# Cloud SQL for PostgreSQL — private IP, password in Secret Manager.
# Cloud mapping:
#   google_sql_database_instance -> AWS RDS instance | Azure DB for PostgreSQL
#   private IP (via PSA)         -> RDS in private subnets | Private Endpoint
#   Secret Manager secret        -> Secrets Manager / SSM | Key Vault
# Security: no public IP, no plaintext password, generated strong password.
# =====================================================================

# ---- Generate a strong DB password (never hardcoded) ----
resource "random_password" "db" {
  length           = 24
  special          = true
  override_special = "!#$%*_-"
}

# ---- Store it in Secret Manager (Key Vault equivalent) ----
resource "google_secret_manager_secret" "db_password" {
  secret_id = "${var.name_prefix}-sql-password"

  replication {
    auto {}
  }

  depends_on = [google_project_service.enabled]
}

resource "google_secret_manager_secret_version" "db_password" {
  secret      = google_secret_manager_secret.db_password.id
  secret_data = random_password.db.result
}

# ---- The Cloud SQL instance ----
resource "google_sql_database_instance" "pg" {
  name             = "${var.name_prefix}-pg"
  database_version = var.sql_database_version
  region           = var.region

  # Don't block terraform destroy in a learning project.
  deletion_protection = false

  settings {
    tier              = var.sql_tier
    availability_type = var.sql_availability_type # ZONAL (dev) or REGIONAL (HA, = RDS Multi-AZ)
    disk_size         = var.sql_disk_size
    disk_type         = "PD_SSD"

    ip_configuration {
      ipv4_enabled    = false # NO public IP
      private_network = google_compute_network.vpc.id
    }

    backup_configuration {
      enabled                        = true
      point_in_time_recovery_enabled = true # WAL-based PITR (like RDS PITR)
    }
  }

  # Instance can only be created after the private peering exists.
  depends_on = [google_service_networking_connection.psa]
}

# ---- A database inside the instance ----
resource "google_sql_database" "app" {
  name     = var.sql_db_name
  instance = google_sql_database_instance.pg.name
}

# ---- An application user, using the generated password ----
resource "google_sql_user" "app" {
  name     = var.sql_user
  instance = google_sql_database_instance.pg.name
  password = random_password.db.result
}

output "sql_private_ip" {
  value       = google_sql_database_instance.pg.private_ip_address
  description = "Private IP apps/pods use to connect to Postgres."
}

output "sql_password_secret" {
  value       = google_secret_manager_secret.db_password.secret_id
  description = "Secret Manager secret holding the DB password (read it, don't print it)."
}
