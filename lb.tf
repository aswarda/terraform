# =====================================================================
# Extra B: Global external HTTP Load Balancer in front of the web VM.
# GCP breaks an LB into several objects. AWS ALB mapping:
#
#   unmanaged instance group  ~ Target Group (membership)
#   named_port "http" 80      ~ TG port
#   google_compute_health_check ~ TG health check
#   backend_service           ~ TG + listener rule backend
#   url_map                   ~ ALB listener rules / routing
#   target_http_proxy         ~ HTTP listener (:80)
#   global_forwarding_rule    ~ ALB frontend (listener + LB IP)
#   global_address            ~ the ALB's public IP
# =====================================================================

# ---- Group the VM so the LB can target it ----
# Zonal unmanaged instance group = a static bag of specific VMs.
resource "google_compute_instance_group" "web_ig" {
  name = "${var.name_prefix}-web-ig"
  zone = var.zone

  instances = [google_compute_instance.web.self_link]

  # Name the port the backend service will route to (container/app port).
  named_port {
    name = "http"
    port = 80
  }
}

# ---- Health check (LB-level) ----
# AWS: Target Group health check. Unhealthy instances are pulled out of rotation.
resource "google_compute_health_check" "http" {
  name = "${var.name_prefix}-http-hc"

  http_health_check {
    port         = 80
    request_path = "/"
  }

  check_interval_sec  = 10
  timeout_sec         = 5
  healthy_threshold   = 2
  unhealthy_threshold = 3
}

# ---- Backend service ----
# Ties the instance group + health check together. AWS: TG + backend config.
resource "google_compute_backend_service" "web_backend" {
  name                  = "${var.name_prefix}-web-backend"
  protocol              = "HTTP"
  port_name             = "http" # matches named_port on the instance group
  load_balancing_scheme = "EXTERNAL_MANAGED"
  timeout_sec           = 30

  health_checks = [google_compute_health_check.http.id]

  backend {
    group           = google_compute_instance_group.web_ig.id
    balancing_mode  = "UTILIZATION"
    max_utilization = 0.8
  }
}

# ---- URL map (routing) ----
# All paths -> the one backend. AWS: listener rules.
resource "google_compute_url_map" "web_urlmap" {
  name            = "${var.name_prefix}-web-urlmap"
  default_service = google_compute_backend_service.web_backend.id
}

# ---- HTTP proxy (the :80 listener) ----
# AWS: the HTTP listener on the ALB.
resource "google_compute_target_http_proxy" "web_proxy" {
  name    = "${var.name_prefix}-web-proxy"
  url_map = google_compute_url_map.web_urlmap.id
}

# ---- Public IP for the LB frontend ----
# Global (anycast) IP. AWS: the ALB's DNS name / IP.
resource "google_compute_global_address" "lb_ip" {
  name = "${var.name_prefix}-lb-ip"
}

# ---- Forwarding rule (the frontend: LB IP + port 80) ----
# AWS: the ALB frontend that binds listener to the LB IP.
resource "google_compute_global_forwarding_rule" "web_fr" {
  name                  = "${var.name_prefix}-web-fr"
  target                = google_compute_target_http_proxy.web_proxy.id
  port_range            = "80"
  ip_address            = google_compute_global_address.lb_ip.id
  load_balancing_scheme = "EXTERNAL_MANAGED"
}

# ---- Allow the LB + health checkers to reach the VM on :80 ----
# Google LB/health-check source ranges. Without this, health checks fail.
resource "google_compute_firewall" "allow_lb_health" {
  name    = "${var.name_prefix}-allow-lb-health"
  network = google_compute_network.vpc.id

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  direction     = "INGRESS"
  source_ranges = ["130.211.0.0/22", "35.191.0.0/16"] # Google LB/HC ranges
  target_tags   = ["web"]
}

output "lb_ip_address" {
  value       = google_compute_global_address.lb_ip.address
  description = "Public IP of the HTTP load balancer."
}
