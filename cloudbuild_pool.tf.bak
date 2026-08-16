# =====================================================================
# Cloud Build PRIVATE worker pool — build workers that live INSIDE your
# VPC (VPC-peered), so they can reach PRIVATE resources: the GKE private
# nodes, Cloud SQL private IP, Memorystore, internal services.
#
# Concept vs Azure/AWS:
#   - Cloud Build default pool = Google's shared public workers (like the
#     Microsoft-hosted / AWS-managed CodeBuild fleet).
#   - PRIVATE pool = the "self-hosted-ish" option: workers peered into YOUR
#     network. Closest GCP analog to your Azure self-hosted agents, except
#     Google still manages the VMs (they're not pods you run).
#
# Reuses the SAME PSA peering (google_service_networking_connection.psa)
# that Cloud SQL and Redis use.
# =====================================================================

resource "google_cloudbuild_worker_pool" "private" {
  name     = "${var.name_prefix}-pool"
  location = var.region

  worker_config {
    machine_type   = var.cb_pool_machine_type
    disk_size_gb   = 100
    no_external_ip = true # workers have NO public IP; egress via Cloud NAT
  }

  network_config {
    # Peer the pool into your VPC so builds can reach private IPs.
    peered_network = google_compute_network.vpc.id
  }

  depends_on = [google_service_networking_connection.psa]
}

output "cloudbuild_worker_pool" {
  value       = google_cloudbuild_worker_pool.private.id
  description = "Full resource path to reference in triggers / cloudbuild options.pool.name"
}
