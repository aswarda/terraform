# Enable the Google APIs this project needs. In Azure resource providers are mostly
# pre-registered; in GCP you must explicitly enable each service API before using it.
locals {
  required_apis = [
    "compute.googleapis.com",          # VPC, Cloud NAT, VMs
    "container.googleapis.com",        # GKE
    "artifactregistry.googleapis.com", # Artifact Registry (ACR equivalent)
    "iam.googleapis.com",              # service accounts / IAM
    "iamcredentials.googleapis.com",   # Workload Identity Federation
    "secretmanager.googleapis.com",    # Secret Manager (Key Vault equivalent)
    "logging.googleapis.com",          # Cloud Logging
    "monitoring.googleapis.com",       # Cloud Monitoring
    "servicenetworking.googleapis.com",
    "sqladmin.googleapis.com",
    "pubsub.googleapis.com",
    "redis.googleapis.com",
    "vpcaccess.googleapis.com",
    "run.googleapis.com",
  ]
}

resource "google_project_service" "enabled" {
  for_each = toset(local.required_apis)

  project = var.project_id
  service = each.value

  # Keep APIs enabled even if this resource is destroyed (avoid breaking other stacks).
  disable_on_destroy = false
}
