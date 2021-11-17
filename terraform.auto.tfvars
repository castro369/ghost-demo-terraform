# Global
project_id = "drone-shuttles-demo"
region     = "europe-west1"
zone       = "europe-west1-b"


# Network Setup
network_name = "vpc-network-ghost"
routing_mode = "GLOBAL"
subnets = [
  {
    subnet_name   = "vpc-subnet-dev"
    subnet_ip     = "10.0.2.0/24"
    subnet_region = "europe-west1"
  }
]


# Cloud SQL
db_name                            = "ghost-db"
db_random_instance_name            = false
database_version                   = "MYSQL_5_7"
db_tier                            = "db-n1-standard-1"
db_availability_type               = "REGIONAL"
db_disk_autoresize                 = true
db_maintenance_window_day          = 6
db_maintenance_window_hour         = 2
db_encryption_key_name             = null
db_maintenance_window_update_track = "stable"
enable_default_db                  = false
db_enable_default_user             = true
db_user_name                       = "root"
db_user_password                   = "123qwe"
db_deletion_protection             = true
db_ipv4_enabled                    = true
db_require_ssl                     = false
db_private_network                 = null
db_authorized_networks             = []
authorized_networks = [{
  name  = "home-network"
  value = "82.155.238.213"
}]

db_backup_binary_log_enabled             = true
db_backup_enabled                        = true
db_backup_location                       = "eu"
db_retained_backups                      = 365
db_backup_retention_unit                 = "COUNT"
db_backup_start_time                     = "02:00"
db_backup_transaction_log_retention_days = "7"


# Read Replica
read_replica_deletion_protection = true
read_replica_failover_target     = true
read_replica_tier                = "db-n1-standard-1"
read_replica_activation_policy   = "ALWAYS"
read_replica_disk_size           = "10"
read_replica_disk_type           = "PD_SSD"
read_replica_pricing_plan        = "PER_USE"
read_replica_user_labels         = null
read_replica_zone                = "europe-west1-b"

# HTTP Load Balancer
private_key             = "certificates/key.key"
certificate             = "certificates/certificate.pem"
neg_name                = "serverless-neg"
network_endpoint_type   = "SERVERLESS"
lb_name                 = "lb-https"
ssl                     = true
use_ssl_certificates    = true
enable_cdn              = false
security_policy         = null
custom_request_headers  = null
custom_response_headers = null


# Cloud Run
cloud_run_service_name = "ci-cloud-run-ghost"
cloud_run_image        = "ghost"
container_concurrency  = 80
cloud_run_members      = ["allUsers"]

cloud_run_ports = {
  "name" : "http1",
  "port" : 2368
}

cloud_run_maxScale              = 100
cloud_run_minScale              = 1
cloud_run_execution_environment = "gen1"

cloud_run_cpu    = "1000m"
cloud_run_memory = "512Mi"


# Secret Manager
secret_db_client      = "DB_CLIENT"
secret_db_client_data = "mysql"

secret_db_user      = "DB_USER"
secret_db_user_data = "root"

secret_db_pass      = "DB_PASS"
secret_db_pass_data = "123qwe"

secret_db_name      = "DB_NAME"
secret_db_name_data = "ghost"

secret_connection_socket = "DB_CON"

secret_url      = "URL"
secret_url_data = "http://localhost:2368"

secret_service_name = "SERVICE_NAME"


# Cloud Build Trigger
trigger_name           = "cicd-trigger"
github_owner           = "antoniocauk"
github_name            = "ghost-demo-cicd"
github_branch          = "^main$"
github_comment_control = "COMMENTS_ENABLED"
trigger_filename       = "cloudbuild.yaml"