# =====================================================================
# Step 4: Artifact Registry (Docker repo) + let GKE nodes pull from it.
# Cloud mapping:
#   Artifact Registry repo -> AWS ECR repository | Azure ACR
#   artifactregistry.reader on node SA -> ECR read on EKS node role | AcrPull
# =====================================================================

# ---- Docker repository ----
resource "google_artifact_registry_repository" "docker" {
  location      = var.region
  repository_id = "${var.name_prefix}-docker"
  description   = "Docker images for the ${var.name_prefix} project"
  format        = "DOCKER"

  depends_on = [google_project_service.enabled]
}

# ---- Let the GKE node SA PULL private images ----
# Scoped to THIS repo (least privilege) rather than project-wide.
resource "google_artifact_registry_repository_iam_member" "nodes_pull" {
  location   = google_artifact_registry_repository.docker.location
  repository = google_artifact_registry_repository.docker.name
  role       = "roles/artifactregistry.reader"
  member     = "serviceAccount:${google_service_account.gke_nodes.email}"
}

output "artifact_registry_repo" {
  value       = "${var.region}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.docker.repository_id}"
  description = "Base path to tag/push images, e.g. <repo>/sampleapp:1"
}
