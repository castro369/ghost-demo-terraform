# Random Number resource for naming purposes
resource "random_id" "suffix" {
  byte_length = 4
}

# Base Network Setup
module "network" {
  source       = "terraform-google-modules/network/google"
  version      = "4.0.0"
  project_id   = var.project_id
  network_name = var.network_name
  routing_mode = var.routing_mode
  subnets      = var.subnets
}

# Reserve global internal address range for the peering
resource "google_compute_global_address" "cloud_sql_private_ip_address" {
  name          = "sql-ip"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = "20"
  network       = module.network.network_self_link

  depends_on = [
    module.network
  ]
}

resource "google_service_networking_connection" "cloud_sql_priv_serv_conn" {
  network                 = module.network.network_self_link
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.cloud_sql_private_ip_address.name]
}

# Cloud SQL
module "mysql_db" {
  source  = "GoogleCloudPlatform/sql-db/google//modules/mysql"
  version = "8.0.0"

  project_id              = var.project_id
  name                    = "${var.db_name}-${random_id.suffix.hex}"
  random_instance_name    = false
  database_version        = var.database_version
  region                  = var.region
  zone                    = var.zone
  tier                    = var.db_tier
  availability_type       = var.db_availability_type
  disk_autoresize         = true
  maintenance_window_day  = 6
  maintenance_window_hour = 2
  encryption_key_name     = null

  deletion_protection = var.db_deletion_protection

  backup_configuration = {
    "binary_log_enabled" : true,
    "enabled" : true,
    "location" : "eu",
    "retained_backups" : 7,
    "retention_unit" : "COUNT",
    "start_time" : "02:00",
    "transaction_log_retention_days" : "7"
  }

  additional_databases = [
    { name = var.db_database_name, charset = "utf8mb4", collation = "utf8mb4_general_ci" }
  ]

  additional_users = [
    {
      name     = var.db_user_name
      password = var.db_user_password
      host     = "% (any host)"
      type     = "BUILT_IN"
    }
  ]

  ip_configuration = {
    ipv4_enabled        = false
    require_ssl         = false
    private_network     = module.network.network_self_link
    authorized_networks = []
  }

  read_replicas = [
    {
      name           = "r-${random_id.suffix.hex}"
      tier           = var.db_tier
      zone           = var.read_replica_zone
      database_flags = []
      ip_configuration = {
        ipv4_enabled        = false
        private_network     = module.network.network_id
        require_ssl         = false
        authorized_networks = []
      }
      disk_autoresize     = true
      disk_size           = "10"
      disk_type           = "PD_SSD"
      user_labels         = null
      encryption_key_name = null
    }
  ]

  module_depends_on = [
    google_service_networking_connection.cloud_sql_priv_serv_conn
  ]
}
/*
resource "google_sql_database_instance" "mysql_sql_replica" {
  name                 = "${module.mysql_db.instance_name}-replica"
  region               = var.region
  database_version     = var.database_version
  master_instance_name = module.mysql_db.instance_name

  replica_configuration {
    # connect_retry_interval = "${lookup(var.replica, "retry_interval", "60")}"
    failover_target = true
  }

  settings {
    tier                   = var.db_tier
    disk_type              = "PD_SSD"
    disk_size              = "10"
    disk_autoresize        = true
    activation_policy      = "ALWAYS"
    availability_type      = "REGIONAL"

    location_preference {
      zone = var.zone
    }

    /*
    maintenance_window {
      day          = 6
      hour         = 2
      update_track = "stable"
    }
   
  }
}
 */
# SSL certificate
resource "google_compute_ssl_certificate" "ssl_certificate" {
  name_prefix = "ssl-certificate-"
  private_key = file("${var.private_key}")
  certificate = file("${var.certificate}")

  lifecycle {
    create_before_destroy = true
  }
}

# Load Balancer
module "lb-http" {
  source  = "GoogleCloudPlatform/lb-http/google//modules/serverless_negs"
  version = "6.1.1"
  name    = "lb-https"
  project = var.project_id

  ssl                  = var.ssl
  https_redirect       = var.ssl
  ssl_certificates     = [google_compute_ssl_certificate.ssl_certificate.self_link]
  use_ssl_certificates = true

  backends = {
    default = {
      description = null
      groups = [
        {
          group = google_compute_region_network_endpoint_group.serverless_neg.id
        }
      ]
      enable_cdn              = false
      security_policy         = null
      custom_request_headers  = null
      custom_response_headers = null

      iap_config = {
        enable               = false
        oauth2_client_id     = ""
        oauth2_client_secret = ""
      }
      log_config = {
        enable      = false
        sample_rate = null
      }
    }
  }
}

# Network Endpoint Group
resource "google_compute_region_network_endpoint_group" "serverless_neg" {
  provider              = google-beta
  name                  = var.neg_name
  network_endpoint_type = "SERVERLESS"
  region                = var.region
  cloud_run {
    service = module.cloud_run.service_name
  }
}

# Serverless VPC Access Connector
resource "google_vpc_access_connector" "serverless_connector" {
  provider       = google-beta
  name           = var.serverless_connector_name
  region         = var.region
  ip_cidr_range  = "10.8.0.0/28"
  network        = module.network.network_name
  machine_type   = "e2-standard-4"
  min_instances  = 2
  max_instances  = 3
  max_throughput = 300
}

# Cloud Run
module "cloud_run" {
  source       = "GoogleCloudPlatform/cloud-run/google"
  version      = "0.1.1"
  service_name = var.cloud_run_service_name
  project_id   = var.project_id
  location     = var.region
  image        = var.cloud_run_image
  container_concurrency  = 80

  members = ["allUsers"]

  ports = {
    "name" : "http1",
    "port" : 2368
  }

  template_annotations = {
    "autoscaling.knative.dev/maxScale"        = 100
    "autoscaling.knative.dev/minScale"        = 1
    "run.googleapis.com/vpc-access-connector" = google_vpc_access_connector.serverless_connector.id
    "run.googleapis.com/vpc-access-egress"    = "all-traffic"
  }

  limits = {
    cpu    = "1000m"
    memory = "512Mi"
  }

  env_secret_vars = [
    {
      name = "database__client"
      value_from = [{
        secret_key_ref = {
          key = "latest"
          name = "DB_CLIENT"
        }
      }]
    },
    {
      name = "database__connection__user"
      value_from = [{
        secret_key_ref = {
          key = "latest"
          name = "DB_USER"
        }
      }]
    },
    {
      name = "database__connection__password"
      value_from = [{
        secret_key_ref = {
          key = "latest"
          name = "DB_PASS"
        }
      }]
    },
    {
      name = "database__connection__database"
      value_from = [{
        secret_key_ref = {
          key  = "latest"
          name = "DB_NAME"
        }
      }]
    },
    {
      name = "database__connection__socketPath"
      value_from = [{
        secret_key_ref = {
          key  = "latest"
          name = "DB_CON"
        }
      }]
    },
    {
      name = "url"
      value_from = [{
        secret_key_ref = {
          key  = "latest"
          name = "URL"
        }
      }]
    }
  ]


  depends_on = [
    null_resource.docker_build
  ]
}

# Secret Manager
resource "google_secret_manager_secret" "secret_db_client" {
  project   = var.project_id
  secret_id = "DB_CLIENT"

  replication {
    automatic = true
  }
  lifecycle {
    ignore_changes = [
      labels
    ]
  }
}

resource "google_secret_manager_secret_version" "secret_version_db_client" {
  secret      = google_secret_manager_secret.secret_db_client.id
  secret_data = "mysql"

  lifecycle {
    ignore_changes = all
  }

  depends_on = [
    module.mysql_db
  ]
}

resource "google_secret_manager_secret" "secret_db_user" {
  project   = var.project_id
  secret_id = "DB_USER"

  replication {
    automatic = true
  }
  lifecycle {
    ignore_changes = [
      labels
    ]
  }
}

resource "google_secret_manager_secret_version" "secret_version_db_user" {
  secret      = google_secret_manager_secret.secret_db_user.id
  secret_data = "ghost"

  lifecycle {
    ignore_changes = all
  }
}

resource "google_secret_manager_secret" "secret_db_pass" {
  project   = var.project_id
  secret_id = "DB_PASS"

  replication {
    automatic = true
  }
  lifecycle {
    ignore_changes = [
      labels
    ]
  }
}

resource "google_secret_manager_secret_version" "secret_version_db_pass" {
  secret      = google_secret_manager_secret.secret_db_pass.id
  secret_data = "123qwe"

  lifecycle {
    ignore_changes = all
  }
}

resource "google_secret_manager_secret" "secret_db_name" {
  project   = var.project_id
  secret_id = "DB_NAME"

  replication {
    automatic = true
  }
  lifecycle {
    ignore_changes = [
      labels
    ]
  }
}

resource "google_secret_manager_secret_version" "secret_version_db_name" {
  secret      = google_secret_manager_secret.secret_db_name.id
  secret_data = "ghost"

  lifecycle {
    ignore_changes = all
  }
}



resource "google_secret_manager_secret" "secret_connection_socket" {
  project   = var.project_id
  secret_id = "DB_CON"

  replication {
    automatic = true
  }
  lifecycle {
    ignore_changes = [
      labels
    ]
  }
}

resource "google_secret_manager_secret_version" "secret_version_connection_socket" {
  secret      = google_secret_manager_secret.secret_connection_socket.id
  secret_data = "/cloudsql/${module.mysql_db.instance_connection_name}"

  lifecycle {
    ignore_changes = all
  }
}

resource "google_secret_manager_secret" "secret_url" {
  project   = var.project_id
  secret_id = "URL"

  replication {
    automatic = true
  }
  lifecycle {
    ignore_changes = [
      labels
    ]
  }
}

resource "google_secret_manager_secret_version" "secret_version_url" {
  secret      = google_secret_manager_secret.secret_url.id
  secret_data = "http://localhost:2368"

  lifecycle {
    ignore_changes = all
  }
}

resource "google_secret_manager_secret" "secret_service_name" {
  project   = var.project_id
  secret_id = "SERVICE_NAME"

  replication {
    automatic = true
  }
  lifecycle {
    ignore_changes = [
      labels
    ]
  }
}

resource "google_secret_manager_secret_version" "secret_version_service_name" {
  secret      = google_secret_manager_secret.secret_service_name.id
  secret_data = module.cloud_run.service_name

  lifecycle {
    ignore_changes = all
  }
}

# Null Resource to push image to GCR
resource "null_resource" "docker_build" {
  /*
  triggers = {
    always_run = timestamp()

  }
  */
  provisioner "local-exec" {
    working_dir = path.module
    command     = "gcloud builds submit --config ../cloudbuild.yaml ../"
  }

  depends_on = [
    google_secret_manager_secret_version.secret_version_connection_socket
  ]
}

# Cloud Build Trigger CICD
resource "google_cloudbuild_trigger" "cicd-trigger" {
  name = "cicd-trigger"
  project = var.project_id

  github {
    owner = "antoniocauk"
    name = "ghost-demo-cicd"
    pull_request {
      branch = "^main$"
      comment_control = "COMMENTS_ENABLED"
    }
  }
  filename = "cloudbuild.yaml"
}
