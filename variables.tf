# Global
variable "project_id" {
  description = "GCP Project id"
  type        = string
}

variable "backend_prefix" {
  description = "Backend Prefix"
  type        = string
}

variable "region" {
  description = "Project Region"
}

variable "zone" {
  description = "Project Zone"
}

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

variable "authorized_networks" {
  type        = list(map(string))
  description = "List of mapped public networks authorized to access to the instances. Default - short range of GCP health-checkers IPs"
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

variable "db_deletion_protection" {
  description = "Cloud SQL Delete Protection"
}

variable "db_read_replica_deletion_protection" {
  description = "Cloud SQL Read Replica Delete Protection"
}

variable "db_user_name" {
  description = "Cloud SQL default user name"
}

variable "db_user_password" {
  description = "Cloud SQL default password"
}

variable "db_database_name" {
  description = "Cloud SQL default database name"
}

variable "db_availability_type" {
  description = "Cloud SQL Availability Type"
}

variable "read_replica_zone" {
  description = "Zone for Read Replica"
}

# Load Balancer
variable "ssl" {
  type        = bool
  description = "Using SSL"
}

variable "private_key" {
  description = "Name of file with Private Key"
}

variable "certificate" {
  description = "Name of file with Certificate"
}

variable "domain" {
  description = "Name of Domain"
}

# Connector and NEG

variable "neg_name" {
  description = "Name Network Endpoint Group"
}

variable "serverless_connector_name" {
  description = "Serverless Connector Name"
}

# Cloud Run
variable "cloud_run_service_name" {
  description = "Name of Cloud Run service"
}

variable "cloud_run_image" {
  description = "Name of Cloud Run Image"
}


# Secret Manager
variable "secrets" {
  type        = map(any)
  description = "Secrets of Secret Manager"
}




/*


variable "container_image" {
  description = "Container Image"
}

variable "instance_template_name_prefix" {
  description = "Prefix Instance Template"
}

variable "instance_template_service_account" {
  type = object({ email = string, scopes = set(string) })
  description = "Service Account for instance template"
}

variable "autoscaling_metric" {
  type = list(object({ name = string, target = number, type = string }))
  description = "Autoscaling Metric"
}

variable "tags" {
  description = "Tags"
}

variable "instance_template_machine_type" {
  description = "Instance Template Machine Type"
}

variable "mig_name" {
  description = "Name of Managed Instance Group"
}

variable "mig_instance_count" {
  description = "Number of Instances Managed Instance Group"
}

# IP Addresses
variable "global_ip_addresses" {
  type = map(any)
  description = "Name of Managed Instance Group"
}


# Firewall Rules
variable "fw_rules" {
  type = map(any)
  description = "Name of Managed Instance Group"
}


*/
