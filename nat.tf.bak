# ---- Cloud Router ----
# Cloud NAT requires a Cloud Router to run on. No direct AWS/Azure analog (it's plumbing);
# think of it as the control plane the NAT service attaches to.
resource "google_compute_router" "router" {
  name    = "${var.name_prefix}-router"
  region  = var.region
  network = google_compute_network.vpc.id
}

# ---- Cloud NAT ----
# Gives private nodes/pods OUTBOUND internet without public IPs.
# AWS: NAT Gateway | Azure: NAT Gateway (exactly what you attached to the AKS subnet).
resource "google_compute_router_nat" "nat" {
  name   = "${var.name_prefix}-nat"
  router = google_compute_router.router.name
  region = var.region

  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}
