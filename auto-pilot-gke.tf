# ---- GKE Autopilot cluster ----
# Autopilot = fully managed nodes/pools -- Google handles node provisioning,
# scaling, upgrades, security hardening. You only define workloads (no node_pool
# resources at all -- that's the key difference from Standard mode above).
# AKS analogy: closest to AKS "Automatic" mode (newer AKS SKU).
resource "google_container_cluster" "gke_autopilot" {
  name     = "${var.name_prefix}-gke-autopilot"
  location = var.region # Autopilot clusters are REGIONAL only (no zonal option).

  enable_autopilot = true

  network    = google_compute_network.vpc.id
  subnetwork = google_compute_subnetwork.subnet.id

  # VPC-native is mandatory for Autopilot (no flag needed -- it's implicit),
  # but secondary ranges still need to be specified.
  ip_allocation_policy {
    cluster_secondary_range_name  = "pods"
    services_secondary_range_name = "services"
  }

  # Private nodes -- same concept as Standard. Autopilot nodes are always
  # private by design; this just controls the control-plane endpoint side.
  private_cluster_config {
    enable_private_nodes    = true
    enable_private_endpoint = false
    master_ipv4_cidr_block  = var.master_cidr
  }

  # Workload Identity is ALWAYS ON in Autopilot -- cannot be disabled,
  # so you technically don't even need to declare this block, but explicit is fine.
  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }

  release_channel {
    channel = "REGULAR" # Autopilot REQUIRES a release channel -- can't use "UNSPECIFIED".
  }

  deletion_protection = false
  depends_on           = [google_project_service.enabled]
  timeouts {
    create = "30m"
    update = "30m"
    delete = "30m"
  }
}
