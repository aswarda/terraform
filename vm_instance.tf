# =====================================================================
# Extra A: a single VM with a public IP, a dedicated firewall, and a
# startup script ("custom data").  Cloud mapping:
#   GCE instance  -> AWS EC2            | Azure VM
#   startup-script metadata -> AWS user_data | Azure custom_data
#   firewall rule (target tag) -> AWS Security Group | Azure NSG
# =====================================================================

# ---- Static public IP (so the address survives stop/start) ----
# AWS: Elastic IP | Azure: Public IP (Static).
resource "google_compute_address" "web_ip" {
  name   = "${var.name_prefix}-web-ip"
  region = var.region
}

# ---- The VM ----
resource "google_compute_instance" "web" {
  name         = "${var.name_prefix}-web"
  machine_type = var.vm_machine_type
  zone         = var.zone

  # "network tags" attach firewall rules to this VM (acts like an NSG binding).
  tags = ["web", "ssh-iap"]

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-12"
      size  = 20
      type  = "pd-standard"
    }
  }

  network_interface {
    network    = google_compute_network.vpc.id
    subnetwork = google_compute_subnetwork.subnet.id

    # This access_config block is what assigns a PUBLIC IP.
    # Remove the block entirely for a private-only VM.
    access_config {
      nat_ip = google_compute_address.web_ip.address
    }
  }

  # "custom data": runs on first boot. Installs nginx and writes a page.
  metadata_startup_script = <<-EOT
    #!/bin/bash
    set -e
    apt-get update
    apt-get install -y nginx
    echo "<h1>Hello from ${var.name_prefix}-web ($(hostname))</h1>" > /var/www/html/index.html
    systemctl enable nginx
    systemctl restart nginx
  EOT

  # Least-privilege: no broad scopes; VM only needs logging/monitoring.
  service_account {
    email  = google_service_account.gke_nodes.email
    scopes = ["cloud-platform"]
  }
}

# ---- Firewall: allow HTTP 80 from the internet to VMs tagged "web" ----
# Dedicated rule scoped by target_tags (your "dedicated NSG" ask).
resource "google_compute_firewall" "allow_http" {
  name    = "${var.name_prefix}-allow-http"
  network = google_compute_network.vpc.id

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  direction     = "INGRESS"
  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["web"]
}

# ---- Firewall: allow SSH ONLY from Google IAP (never public 0.0.0.0/0) ----
# Connect with: gcloud compute ssh <vm> --tunnel-through-iap
# MB policy: no public management ports.
resource "google_compute_firewall" "allow_ssh_iap" {
  name    = "${var.name_prefix}-allow-ssh-iap"
  network = google_compute_network.vpc.id

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  direction     = "INGRESS"
  source_ranges = ["35.235.240.0/20"] # Google IAP range
  target_tags   = ["ssh-iap"]
}
