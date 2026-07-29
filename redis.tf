# =====================================================================
# Memorystore for Redis — managed, private Redis.
# Cloud mapping:
#   google_redis_instance -> AWS ElastiCache for Redis | Azure Cache for Redis
#   STANDARD_HA tier       -> ElastiCache with replica + Multi-AZ failover
#   BASIC tier             -> single node, no failover (dev)
# Private-only: reachable from the VPC (GKE pods/VMs), never public.
# =====================================================================

resource "google_redis_instance" "cache" {
  name           = "${var.name_prefix}-redis"
  tier           = var.redis_tier        # BASIC or STANDARD_HA
  memory_size_gb = var.redis_memory_gb
  region         = var.region

  redis_version = var.redis_version

  # Reach Redis over the SAME private-service-access peering the SQL uses.
  connect_mode            = "PRIVATE_SERVICE_ACCESS"
  authorized_network      = google_compute_network.vpc.id
  transit_encryption_mode = "SERVER_AUTHENTICATION" # TLS in transit
  auth_enabled            = true                     # require AUTH token

  depends_on = [google_service_networking_connection.psa]
}

output "redis_host" {
  value       = google_redis_instance.cache.host
  description = "Private IP/host of the Redis endpoint."
}

output "redis_port" {
  value       = google_redis_instance.cache.port
  description = "Redis port (default 6379)."
}
