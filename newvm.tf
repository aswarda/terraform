# ---- Static public IP for the NEW VM ----
resource "google_compute_address" "web_ip_2" {
  name   = "${var.name_prefix}-web-ip-2"
  region = var.region
}

# ---- The NEW VM (web2) with modified startup script ----
resource "google_compute_instance" "web2" {
  name         = "${var.name_prefix}-web2"
  machine_type = var.vm_machine_type
  zone         = var.zone

  tags = ["web", "ssh-iap"] # Automatically inherits both firewall rules

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

    access_config {
      nat_ip = google_compute_address.web_ip_2.address
    }
  }

  # Your updated custom data script
  metadata_startup_script = <<-EOT
    #!/bin/bash
    set -e
    apt-get update
    apt-get install -y nginx
    echo "<h1>Hii from ${var.name_prefix}-web ($(hostname))</h1>" > /var/www/html/index.html
    systemctl enable nginx
    systemctl restart nginx
  EOT

  service_account {
    email  = google_service_account.gke_nodes.email
    scopes = ["cloud-platform"]
  }
}
