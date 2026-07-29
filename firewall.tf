# ---- Firewall rules ----
# GCP firewall rules are VPC-level (not attached to a subnet/NIC like NSGs).
# AWS: Security Groups + NACLs | Azure: NSG. Default: all ingress denied, all egress allowed.

# Allow internal traffic between resources inside the VPC (nodes<->pods<->services).
resource "google_compute_firewall" "allow_internal" {
  name    = "${var.name_prefix}-allow-internal-firewall"
  network = google_compute_network.vpc.id

  allow {
    protocol = "tcp"
    ports    = ["0-65535"]
  }
  allow {
    protocol = "udp"
    ports    = ["0-65535"]
  }
  allow {
    protocol = "icmp"
  }

  direction     = "INGRESS"
  source_ranges = [var.subnet_cidr, var.pods_cidr, var.services_cidr]
}

# NOTE: We intentionally do NOT open SSH (22) from the internet.
# Your MB security policy forbids public management ports — use IAP/bastion instead.
