# Global
variable "project_id" {
  description = "GCP Project id"
  type        = string
}

variable "region" {
  description = "Project Region"
}

variable "zone" {
  description = "Project Zone"
}


# Network
variable "network_name" {
  description = "Name of Network"
}

variable "routing_mode" {
  description = "Routing Mode"
}

variable "subnets" {
  type        = list(map(any))
  description = "Routing Mode"
}

# SQL
variable "db_name" {
  description = "The name of the SQL Database instance"
}

variable "db_random_instance_name" {
  description = "Random Instance Name SQL"
}

variable "database_version" {
  description = "Version of Database"
}

variable "db_tier" {
  description = "Tier of Database Instance"
}

variable "db_availability_type" {
  description = "Cloud SQL Availability Type"
}

variable "db_disk_autoresize" {
  description = "Disk Autoresize"
}

variable "db_maintenance_window_day" {
  description = "Day of the week maintenance window"
}

variable "db_maintenance_window_hour" {
  description = "Hour of day maintenance window"
}

variable "db_encryption_key_name" {
  description = "Encryption key name"
}

variable "db_maintenance_window_update_track" {
  description = "Maintenance Window update track"
}

variable "enable_default_db" {
  description = "Enable Default Database"
}

variable "db_enable_default_user" {
  description = "Enable Default User"
}

variable "db_user_name" {
  description = "Database Username"
}

variable "db_user_password" {
  description = "Database Password"
}

variable "db_deletion_protection" {
  description = "Database Deletion Protection"
}

variable "db_ipv4_enabled" {
  description = "Enable IPV4"
}

variable "db_require_ssl" {
  description = "Database Require SSL"
}

variable "db_private_network" {
  description = "Database Private Network"
}

variable "db_authorized_networks" {
  type        = list(map(string))
  description = "List of mapped public networks authorized to access to the instances. Default - short range of GCP health-checkers IPs"
}


variable "db_backup_binary_log_enabled" {
  description = "Enable Binary Log"
}

variable "db_backup_enabled" {
  description = "Enable Database Backup"
}

variable "db_backup_location" {
  description = "Database Backup Location"
}

variable "db_retained_backups" {
  description = "Database Retained Backups"
}

variable "db_backup_retention_unit" {
  description = "Database Retention Unit"
}

variable "db_backup_start_time" {
  description = "Database Backup Start Time"
}

variable "db_backup_transaction_log_retention_days" {
  description = "Database Transaction Log Retention Days"
}

variable "read_replica_deletion_protection" {
  description = "Read Replica Deletion Protection"
}

variable "read_replica_failover_target" {
  description = "Read Replica Failover Target"
}

variable "read_replica_tier" {
  description = "Read Replica Tier"
}

variable "read_replica_activation_policy" {
  description = "Read Replica Activation Policy"
}

variable "read_replica_disk_size" {
  description = "Read Replica Disk Size"
}

variable "read_replica_disk_type" {
  description = "Read Replica Disk Type"
}

variable "read_replica_pricing_plan" {
  description = "Read Replica Pricing Plan"
}

variable "read_replica_user_labels" {
  description = "Read Replica User Labels"
}

variable "read_replica_zone" {
  description = "Zone for Read Replica"
}


# HTTP Load Balancer
variable "private_key" {}
variable "certificate" {}
variable "neg_name" {}
variable "network_endpoint_type" {}
variable "lb_name" {}
variable "ssl" {}
variable "use_ssl_certificates" {}
variable "enable_cdn" {}
variable "security_policy" {}
variable "custom_request_headers" {}
variable "custom_response_headers" {}

# Cloud Run
variable "cloud_run_service_name" {}
variable "cloud_run_image" {}
variable "container_concurrency" {}
variable "cloud_run_members" {}

variable "cloud_run_ports" {
  type = object({ name = string, port = number })
}

variable "cloud_run_maxScale" {}
variable "cloud_run_minScale" {}
variable "cloud_run_execution_environment" {}
variable "cloud_run_cpu" {}
variable "cloud_run_memory" {}

# Secret Manager
variable "secret_db_client" {}
variable "secret_db_client_data" {}
variable "secret_db_user" {}
variable "secret_db_user_data" {}
variable "secret_db_pass" {}
variable "secret_db_pass_data" {}
variable "secret_db_name" {}
variable "secret_db_name_data" {}
variable "secret_connection_socket" {}
variable "secret_url" {}
variable "secret_url_data" {}

# Cloud Build Trigger
variable "trigger_name" {
  description = "Trigger Name"
}

variable "github_owner" {
  description = "Trigger Github Owner"
}

variable "github_name" {
  description = "Trigger Github Name"
}

variable "github_branch" {
  description = "Trigger Github Branch"
}

variable "github_comment_control" {
  description = "Trigger Comment Control"
}

variable "trigger_filename" {
  description = "Trigger Filename"
}
