# ---- VPC ----
# GCP VPC is GLOBAL (spans all regions).  AWS: VPC is regional | Azure: VNet is regional.
resource "google_compute_network" "vpc" {
  name                    = "${var.name_prefix}-vpc"
  auto_create_subnetworks = false # we create subnets manually (custom mode)
  routing_mode            = "REGIONAL"
}

# ---- Subnet ----
# Subnets are REGIONAL in GCP.  AWS: subnet = per-AZ | Azure: subnet inside a VNet.
# Secondary ranges give pods & services their own IP space (VPC-native GKE).
# AWS EKS: similar to CNI secondary CIDRs | Azure: like Azure CNI pod subnet.
resource "google_compute_subnetwork" "subnet" {
  name          = "${var.name_prefix}-subnet"
  network       = google_compute_network.vpc.id
  region        = var.region
  ip_cidr_range = var.subnet_cidr # nodes live here

  # Required for GKE nodes to reach Google APIs without external IPs.
  private_ip_google_access = true

  secondary_ip_range {
    range_name    = "pods"
    ip_cidr_range = var.pods_cidr
  }
  secondary_ip_range {
    range_name    = "services"
    ip_cidr_range = var.services_cidr
  }
}
