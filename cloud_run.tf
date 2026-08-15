# =====================================================================
# Cloud Run service — PUBLIC ingress (HTTPS URL) but EGRESS through YOUR VPC
# via a Serverless VPC Access connector. This is the "Cloud Run on the
# project VPC" pattern you want to talk about in the interview:
#   - Anyone can reach the service on its public https URL (public ingress)
#   - The service's OUTBOUND traffic exits through aswarda-dev-vpc, so it can
#     reach private resources (Cloud SQL private IP, Memorystore, internal svc).
#
# Cloud Run gives you automatically (so you DON'T configure them):
#   - the HTTPS URL   -> no load balancer / no Ingress needed
#   - autoscaling 0..N-> you only set min/max instances + concurrency
# =====================================================================

# ---- Serverless VPC Access connector (bridges Cloud Run -> your VPC) ----
# Needs a dedicated /28 that does NOT overlap your other ranges
# (subnet 10.10.0.0/20, pods 10.20/16, svcs 10.30/20, control-plane 172.16.0.0/28).
resource "google_vpc_access_connector" "serverless" {
  name          = "${var.name_prefix}-cr-conn"
  region        = var.region
  network       = google_compute_network.vpc.name
  ip_cidr_range = var.cloud_run_connector_cidr

  min_instances = 2
  max_instances = 3

  depends_on = [google_project_service.enabled]
}

# ---- Cloud Run service ----
resource "google_cloud_run_v2_service" "app" {
  name     = "${var.name_prefix}-run"
  location = var.region
  deletion_protection = false

  # Public ingress: reachable from the internet on the https URL.
  ingress = "INGRESS_TRAFFIC_ALL"

  template {
    # Autoscaling knobs (NOT a fixed container count).
    scaling {
      min_instance_count = var.cloud_run_min_instances
      max_instance_count = var.cloud_run_max_instances
    }

    # Route egress through your VPC via the connector.
    vpc_access {
      connector = google_vpc_access_connector.serverless.id
      egress    = "PRIVATE_RANGES_ONLY" # only VPC/private traffic uses the connector; public egress stays direct
    }

    containers {
      image = var.cloud_run_image

      ports {
        container_port = 8080
      }

      resources {
        limits = {
          cpu    = "1"
          memory = "512Mi"
        }
      }
    }

    # Requests handled concurrently by one instance before scaling out.
    max_instance_request_concurrency = 80
  }

  depends_on = [google_project_service.enabled]
}

# ---- Make it publicly invokable (allow unauthenticated) ----
resource "google_cloud_run_v2_service_iam_member" "public" {
  name     = google_cloud_run_v2_service.app.name
  location = google_cloud_run_v2_service.app.location
  role     = "roles/run.invoker"
  member   = "allUsers"
}

output "cloud_run_url" {
  value       = google_cloud_run_v2_service.app.uri
  description = "Public HTTPS URL of the Cloud Run service."
}
