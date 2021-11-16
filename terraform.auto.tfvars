project_id = "test-mine-as"
region     = "europe-west1"
zone       = "europe-west1-b"

# NETWORK SETUP
network_name = "vpc-network-ghost-last"
routing_mode = "GLOBAL"
subnets = [
  {
    subnet_name   = "vpc-subnet-dev"
    subnet_ip     = "10.0.2.0/24"
    subnet_region = "europe-west1"
  }
]

# Cloud SQL
db_name                             = "ghost-mysql-db"
db_random_instance_name             = false
database_version                    = "MYSQL_5_7"
db_tier                             = "db-n1-standard-1"
db_deletion_protection              = true
db_read_replica_deletion_protection = true
db_user_name                        = "ghost"
db_user_password                    = "123qwe"
db_database_name                    = "ghost"
db_availability_type                = "REGIONAL"
authorized_networks = [{
  name  = "home-network"
  value = "82.155.238.213"
}]
read_replica_zone = "europe-west2-b"

# Load Balancer 
ssl         = true
private_key = "certificates/key.key"
certificate = "certificates/certificate.pem"

domain   = "acastro.xyz"
neg_name = "serverless-neg"

# Cloud Run
cloud_run_service_name    = "ci-cloud-run-ghost"
cloud_run_image           = "ghost"
serverless_connector_name = "vpc-connector-cloud-run"

# Secret Manager
secrets = {
  DB_HOST = {
    secret = "ghost"
  }
  DB_NAME = {
    secret = "ghost"
  }
  DB_PASS = {
    secret = "123qwe"
  }
  DB_PORT = {
    secret = "3306"
  }
  DB_USER = {
    secret = "ghost"
  }
}

