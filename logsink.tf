# 1. Create a dedicated GCS Storage Bucket for long-term log archival
resource "google_storage_bucket" "log_archive" {
  name                        = "${var.name_prefix}-gke-logs-archive"
  location                    = var.region
  storage_class               = "NEARLINE" # Cost-effective for archival logs
  uniform_bucket_level_access = true
  force_destroy               = true

  # Optional: Automatically delete logs after 90 days to save costs
  lifecycle_rule {
    condition {
      age = 90
    }
    action {
      type = "Delete"
    }
  }
}

# 2. Create the Project-Level Log Sink filtering only for GKE logs
resource "google_logging_project_sink" "gke_sink" {
  name        = "${var.name_prefix}-gke-to-gcs-sink"
  description = "Routes GKE stdout, stderr, and system logs to storage bucket"
  destination = "storage.googleapis.com:${google_storage_bucket.log_archive.name}"

  # The filter targets container logs, GKE cluster operations, and node system logs
  filter = <<EOT
    resource.type="k8s_container" OR 
    resource.type="gke_cluster" OR 
    resource.type="gco_node"
  EOT

  unique_writer_identity = true
}

# 3. Grant the Log Sink's automatic writer identity permission to upload files to the bucket
resource "google_storage_bucket_iam_member" "log_sink_writer" {
  bucket = google_storage_bucket.log_archive.name
  role   = "roles/storage.objectCreator"
  
  # Extracts the auto-generated service account string from the sink
  member = google_logging_project_sink.gke_sink.writer_identity
}
