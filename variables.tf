variable "project_id" {
  description = "GCP project ID (globally unique). Azure analogy: the subscription+RG combined."
  type        = string
  default = "project-19163790-d10f-48bc-a87"
}

variable "region" {
  description = "Default region for regional resources (subnets, GKE regional cluster)."
  type        = string
  default     = "us-central1"
}

variable "zone" {
  description = "Default zone for zonal resources."
  type        = string
  default     = "us-central1-a"
}

variable "name_prefix" {
  description = "Prefix for resource names, e.g. 'aswarda-dev'."
  type        = string
  default     = "aswarda-dev"
}


# ---- Network (Step 2) ----
variable "subnet_cidr" {
  description = "Primary CIDR for the subnet (node IPs)."
  type        = string
  default     = "10.10.0.0/20"
}

variable "pods_cidr" {
  description = "Secondary range for GKE pods (VPC-native)."
  type        = string
  default     = "10.20.0.0/16"
}

variable "services_cidr" {
  description = "Secondary range for GKE services (ClusterIPs)."
  type        = string
  default     = "10.30.0.0/20"
}

variable "master_cidr" {
  description = "Private /28 for the GKE control plane (must not overlap other ranges)."
  type        = string
  default     = "172.16.0.0/28"
}

variable "system_machine_type" {
  description = "Machine type for the system node pool."
  type        = string
  default     = "e2-standard-2"
}

variable "workload_machine_type" {
  description = "Machine type for the workload node pool."
  type        = string
  default     = "e2-standard-2"
}

variable "workload_min_nodes" {
  description = "Autoscaler min for the workload pool."
  type        = number
  default     = 1
}

variable "workload_max_nodes" {
  description = "Autoscaler max for the workload pool."
  type        = number
  default     = 3
}

variable "vm_machine_type" {
  description = "Machine type for the standalone web VM."
  type        = string
  default     = "e2-small"
}

# ---- Cloud SQL (RDS equivalent) ----
variable "sql_database_version" {
  description = "Cloud SQL engine/version, e.g. POSTGRES_15."
  type        = string
  default     = "POSTGRES_15"
}
variable "sql_tier" {
  description = "Machine tier for Cloud SQL (db-custom-1-3840 = 1 vCPU / 3.75GB; db-f1-micro for cheapest dev)."
  type        = string
  default     = "db-custom-1-3840"
}
variable "sql_availability_type" {
  description = "ZONAL (single zone, dev) or REGIONAL (HA, = RDS Multi-AZ)."
  type        = string
  default     = "ZONAL"
}
variable "sql_disk_size" {
  description = "Cloud SQL data disk size in GB."
  type        = number
  default     = 10
}
variable "sql_db_name" {
  description = "Name of the application database to create inside the instance."
  type        = string
  default     = "appdb"
}
variable "sql_user" {
  description = "Application DB username (password is generated + stored in Secret Manager)."
  type        = string
  default     = "appuser"
}

# ---- Pub/Sub ----
variable "pubsub_topic_name" {
  description = "Pub/Sub topic name (short form; prefixed at use)."
  type        = string
  default     = "events"
}

# ---- Memorystore Redis (ElastiCache equivalent) ----
variable "redis_tier" {
  description = "BASIC (single node, dev) or STANDARD_HA (replica + failover, = ElastiCache Multi-AZ)."
  type        = string
  default     = "BASIC"
}
variable "redis_memory_gb" {
  description = "Redis capacity in GB."
  type        = number
  default     = 1
}
variable "redis_version" {
  description = "Redis engine version, e.g. REDIS_7_0."
  type        = string
  default     = "REDIS_7_0"
}