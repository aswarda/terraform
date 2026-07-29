terraform {
  required_version = ">= 1.5.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.0"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "~> 6.0"
    }
  }
}

# Main provider. Uses Application Default Credentials (ADC):
#   gcloud auth application-default login
# In CI you'd use Workload Identity Federation instead of a key.
provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}

# google-beta is needed for some GKE features (e.g. certain Workload Identity /
# advanced datapath options). Same auth as above.
provider "google-beta" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}
