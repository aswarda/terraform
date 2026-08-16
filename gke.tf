# ---- GKE cluster ----
# GKE = managed Kubernetes.  AWS: EKS | Azure: AKS (what you built).
# We make it VPC-native (uses the pods/services secondary ranges) and private
# (nodes get no public IPs; egress via Cloud NAT from Step 2).
resource "google_container_cluster" "gke" {
  name     = "${var.name_prefix}-gke"
  location = var.zone # ZONAL cluster = single zone (no 3x node multiplier; fits quota).
  # For prod HA use var.region (regional) but plan node/SSD quota for 3 zones.

  network    = google_compute_network.vpc.id
  subnetwork = google_compute_subnetwork.subnet.id

  # Remove the default node pool; we manage our own pools below.
  # AKS analogy: you always define default_node_pool; here we detach it.
  remove_default_node_pool = true
  initial_node_count       = 1

  # Force the transient default pool onto pd-standard (HDD) so it doesn't consume
  # the small SSD_TOTAL_GB regional quota while the cluster is being created.

  # VPC-native: map pods/services to the subnet's secondary ranges (Step 2).
  ip_allocation_policy {
    cluster_secondary_range_name  = "pods"
    services_secondary_range_name = "services"
  }

  # Private nodes (no public IPs). Control plane endpoint stays public for your kubectl
  # here (learning). Production: set enable_private_endpoint = true + authorized networks.
  private_cluster_config {
    enable_private_nodes    = true
    enable_private_endpoint = false
    master_ipv4_cidr_block  = var.master_cidr
  }

  # Workload Identity: lets pods impersonate a Google SA WITHOUT node keys.
  # AKS analogy: AKS Workload Identity (federated KSA <-> identity).
  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }

  release_channel {
    channel = "REGULAR"
  }

  # GKE requires a node pool to exist; the default one is removed right after create.
  deletion_protection = false

  depends_on = [google_project_service.enabled]
}

# ---- System node pool ----
# Runs system/critical workloads.  AKS analogy: the system node pool.
resource "google_container_node_pool" "system" {
  name     = "system"
  cluster  = google_container_cluster.gke.id
  location = var.zone

  node_count = 1

  node_config {
    machine_type    = var.system_machine_type
    disk_size_gb    = 50
    disk_type       = "pd-standard"
    service_account = google_service_account.gke_nodes.email
    oauth_scopes    = ["https://www.googleapis.com/auth/cloud-platform"]

    # Enable Workload Identity on the node (GKE metadata server).
    workload_metadata_config {
      mode = "GKE_METADATA"
    }

    labels = { pool = "system" }
  }
}

# ---- Workload node pool ----
# Hosts your app workloads, autoscaled.  AKS analogy: the user/workloads node pool.
resource "google_container_node_pool" "workloads" {
  name     = "workloads"
  cluster  = google_container_cluster.gke.id
  location = var.zone

  autoscaling {
    min_node_count = var.workload_min_nodes
    max_node_count = var.workload_max_nodes
  }

  node_config {
    machine_type    = var.workload_machine_type
    disk_size_gb    = 50
    disk_type       = "pd-standard"
    service_account = google_service_account.gke_nodes.email
    oauth_scopes    = ["https://www.googleapis.com/auth/cloud-platform"]

    workload_metadata_config {
      mode = "GKE_METADATA"
    }

    labels = { pool = "workloads" }
  }
}
