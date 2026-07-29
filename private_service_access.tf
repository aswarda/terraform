# =====================================================================
# Private Service Access (PSA) — shared plumbing for PRIVATE-IP managed
# services (Cloud SQL, Memorystore Redis). These Google-managed services
# live in a Google-owned VPC; PSA VPC-peers your VPC to theirs so you
# reach them over private IPs (no public exposure).
#
# Cloud mapping:
#   PSA peering            -> AWS: VPC peering to the RDS/ElastiCache subnet group
#                          -> Azure: Private Endpoint / VNet integration
#   reserved address range -> the block Google carves private IPs from
# =====================================================================

# 1) Reserve an internal CIDR block that Google will hand out private IPs from.
resource "google_compute_global_address" "psa_range" {
  name          = "${var.name_prefix}-psa-range"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = google_compute_network.vpc.id
}

# 2) Create the actual peering connection between your VPC and Google's
#    service producer VPC, using the range reserved above.
resource "google_service_networking_connection" "psa" {
  network                 = google_compute_network.vpc.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.psa_range.name]

  depends_on = [google_project_service.enabled]
}
