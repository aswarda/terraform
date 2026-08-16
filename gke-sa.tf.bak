# ---- Node service account ----
# Dedicated least-privilege identity the GKE nodes run as.
# AWS: EKS node IAM role | Azure: AKS kubelet (node) managed identity.
# Best practice: do NOT use the default Compute Engine SA (over-privileged).
resource "google_service_account" "gke_nodes" {
  account_id   = "${var.name_prefix}-gke-nodes"
  display_name = "GKE node service account"
}

# Minimal roles nodes need to write logs/metrics. (Artifact Registry pull role is
# added in Step 4.)  AWS: managed node role policies | Azure: node identity roles.
resource "google_project_iam_member" "nodes_log_writer" {
  project = var.project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.gke_nodes.email}"
}

resource "google_project_iam_member" "nodes_metric_writer" {
  project = var.project_id
  role    = "roles/monitoring.metricWriter"
  member  = "serviceAccount:${google_service_account.gke_nodes.email}"
}

resource "google_project_iam_member" "nodes_monitoring_viewer" {
  project = var.project_id
  role    = "roles/monitoring.viewer"
  member  = "serviceAccount:${google_service_account.gke_nodes.email}"
}
