# Remote state in a GCS bucket (the GCP equivalent of your azurerm storage backend).
# The bucket MUST exist before `terraform init` (chicken-and-egg, just like Azure).
# Create it once manually (see the bootstrap command I gave you), then init.
#
# GCS backend handles state locking automatically (no separate lock table needed).
terraform {
  backend "gcs" {
    bucket = "aswarda-tfstate-dev" # <-- globally-unique bucket you create first
    prefix = "gke/dev"             # <-- "folder" path for this state (like a key)
  }
}
