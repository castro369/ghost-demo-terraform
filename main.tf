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

# Cloud SQL
module "mysql_db" {
  source  = "GoogleCloudPlatform/sql-db/google//modules/mysql"
  version = "8.0.0"

  project_id                      = var.project_id
  name                            = "${var.db_name}-${random_id.suffix.hex}"
  random_instance_name            = var.db_random_instance_name
  database_version                = var.database_version
  region                          = var.region
  zone                            = var.zone
  tier                            = var.db_tier
  availability_type               = var.db_availability_type
  disk_autoresize                 = var.db_disk_autoresize
  maintenance_window_day          = var.db_maintenance_window_day
  maintenance_window_hour         = var.db_maintenance_window_hour
  encryption_key_name             = var.db_encryption_key_name
  maintenance_window_update_track = var.db_maintenance_window_update_track
  enable_default_db               = var.enable_default_db
  enable_default_user             = var.db_enable_default_user
  user_name                       = var.db_user_name
  user_password                   = var.db_user_password

  deletion_protection = var.db_deletion_protection

  ip_configuration = {
    ipv4_enabled        = var.db_ipv4_enabled
    require_ssl         = var.db_require_ssl
    private_network     = var.db_private_network
    authorized_networks = var.db_authorized_networks
  }

  backup_configuration = {
    "binary_log_enabled" : var.db_backup_binary_log_enabled,
    "enabled" : var.db_backup_enabled,
    "location" : var.db_backup_location,
    "retained_backups" : var.db_retained_backups,
    "retention_unit" : var.db_backup_retention_unit,
    "start_time" : var.db_backup_start_time,
    "transaction_log_retention_days" : var.db_backup_transaction_log_retention_days
  }
}

resource "google_sql_database_instance" "mysql_read_replica" {
  provider             = google-beta
  project              = var.project_id
  name                 = "${module.mysql_db.instance_name}-replica"
  database_version     = var.database_version
  region               = var.region
  master_instance_name = module.mysql_db.instance_name
  deletion_protection  = var.read_replica_deletion_protection
  encryption_key_name  = var.db_encryption_key_name

  replica_configuration {
    failover_target = var.read_replica_failover_target
  }

  settings {
    tier              = var.read_replica_tier
    activation_policy = var.read_replica_activation_policy

    ip_configuration {
      ipv4_enabled    = var.db_ipv4_enabled
      private_network = var.db_private_network
      require_ssl     = var.db_require_ssl
    }

    disk_autoresize = var.db_disk_autoresize
    disk_size       = var.read_replica_disk_size
    disk_type       = var.read_replica_disk_type
    pricing_plan    = var.read_replica_pricing_plan
    user_labels     = var.read_replica_user_labels

    location_preference {
      zone = var.read_replica_zone
    }
  }

  depends_on = [module.mysql_db, module.cloud_run]
  lifecycle {
    ignore_changes = [
      settings[0].disk_size,
      settings[0].maintenance_window,
    ]
  }
}


# SSL certificate
resource "google_compute_ssl_certificate" "ssl_certificate" {
  name_prefix = "ssl-certificate-"
  private_key = file("${var.private_key}")
  certificate = file("${var.certificate}")

  lifecycle {
    create_before_destroy = true
  }
}

# Network Endpoint Group
resource "google_compute_region_network_endpoint_group" "serverless_neg" {
  provider              = google-beta
  name                  = var.neg_name
  network_endpoint_type = var.network_endpoint_type
  region                = var.region
  cloud_run {
    service = module.cloud_run.service_name
  }
}

# Load Balancer
module "lb-http" {
  source  = "GoogleCloudPlatform/lb-http/google//modules/serverless_negs"
  version = "6.1.1"
  name    = var.lb_name
  project = var.project_id

  ssl                  = var.ssl
  https_redirect       = var.ssl
  ssl_certificates     = [google_compute_ssl_certificate.ssl_certificate.self_link]
  use_ssl_certificates = var.use_ssl_certificates

  backends = {
    default = {
      description = null
      groups = [
        {
          group = google_compute_region_network_endpoint_group.serverless_neg.id
        }
      ]
      enable_cdn              = var.enable_cdn
      security_policy         = var.security_policy
      custom_request_headers  = var.custom_request_headers
      custom_response_headers = var.custom_response_headers

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

# Cloud Run
module "cloud_run" {
  source                = "GoogleCloudPlatform/cloud-run/google"
  version               = "0.1.1"
  service_name          = var.cloud_run_service_name
  project_id            = var.project_id
  location              = var.region
  image                 = "gcr.io/${var.project_id}/${var.cloud_run_image}"
  container_concurrency = var.container_concurrency

  members = var.cloud_run_members

  ports = var.cloud_run_ports

  template_annotations = {
    "autoscaling.knative.dev/maxScale"         = var.cloud_run_maxScale
    "autoscaling.knative.dev/minScale"         = var.cloud_run_minScale
    "run.googleapis.com/cloudsql-instances"    = module.mysql_db.instance_connection_name
    "run.googleapis.com/execution-environment" = var.cloud_run_execution_environment
  }

  limits = {
    cpu    = var.cloud_run_cpu
    memory = var.cloud_run_memory
  }

  env_secret_vars = [
    {
      name = "database__client"
      value_from = [{
        secret_key_ref = {
          key  = "latest"
          name = "DB_CLIENT"
        }
      }]
    },
    {
      name = "database__connection__user"
      value_from = [{
        secret_key_ref = {
          key  = "latest"
          name = "DB_USER"
        }
      }]
    },
    {
      name = "database__connection__password"
      value_from = [{
        secret_key_ref = {
          key  = "latest"
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
    google_secret_manager_secret_version.secret_version_connection_socket,
    google_secret_manager_secret_version.secret_version_db_client,
    google_secret_manager_secret_version.secret_version_db_user,
    google_secret_manager_secret_version.secret_version_db_pass,
    google_secret_manager_secret_version.secret_version_db_name,
    google_secret_manager_secret_version.secret_version_connection_socket,
    google_secret_manager_secret_version.secret_version_url
  ]
}

# Secret Manager
resource "google_secret_manager_secret" "secret_db_client" {
  project   = var.project_id
  secret_id = var.secret_db_client

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
  secret_data = var.secret_db_client_data

  lifecycle {
    ignore_changes = all
  }

  depends_on = [
    module.mysql_db
  ]
}

resource "google_secret_manager_secret" "secret_db_user" {
  project   = var.project_id
  secret_id = var.secret_db_user

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
  secret_data = var.secret_db_user_data

  lifecycle {
    ignore_changes = all
  }
}

resource "google_secret_manager_secret" "secret_db_pass" {
  project   = var.project_id
  secret_id = var.secret_db_pass

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
  secret_data = var.secret_db_pass_data

  lifecycle {
    ignore_changes = all
  }
}

resource "google_secret_manager_secret" "secret_db_name" {
  project   = var.project_id
  secret_id = var.secret_db_name

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
  secret_data = var.secret_db_name_data

  lifecycle {
    ignore_changes = all
  }
}



resource "google_secret_manager_secret" "secret_connection_socket" {
  project   = var.project_id
  secret_id = var.secret_connection_socket

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
  secret_id = var.secret_url

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
  secret_data = var.secret_url_data

  lifecycle {
    ignore_changes = all
  }
}

resource "google_secret_manager_secret" "secret_service_name" {
  project   = var.project_id
  secret_id = var.secret_service_name

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

# Cloud Build Trigger CICD
resource "google_cloudbuild_trigger" "cicd-trigger" {
  name    = var.trigger_name
  project = var.project_id

  github {
    owner = var.github_owner
    name  = var.github_name
    pull_request {
      branch          = var.github_branch
      comment_control = var.github_comment_control
    }
  }
  filename = var.trigger_filename
}


# Consuming secrets
data "google_secret_manager_secret_version" "data_secret_db_name" {
  provider = google-beta
  secret   = var.secret_db_name
}

data "google_secret_manager_secret_version" "data_secret_db_pass" {
  provider = google-beta
  secret   = var.secret_db_pass
}

data "google_secret_manager_secret_version" "data_secret_db_user" {
  provider = google-beta
  secret   = var.secret_db_user
}


# Create Bucket for Function code
resource "google_storage_bucket" "bucket" {
  name          = var.bucket_name
  location      = var.bucket_location
  force_destroy = var.bucket_force_destroy

  lifecycle_rule {
    condition {
      age = 3
    }
    action {
      type = "Delete"
    }
  }
}

resource "google_storage_bucket_object" "zip_file" {
  name   = "function.zip"
  source = "function.zip"
  bucket = google_storage_bucket.bucket.name
}

# Cloud Funtion
resource "google_cloudfunctions_function" "delete_posts_function" {
  name        = var.cf_name
  description = var.cf_description
  runtime     = var.cf_runtime

  available_memory_mb   = var.cf_available_memory_mb
  source_archive_bucket = google_storage_bucket.bucket.name
  source_archive_object = google_storage_bucket_object.zip_file.name

  trigger_http          = true
  timeout               = 60
  entry_point           = var.cf_entrypoint

  environment_variables = {
    DB_NAME = data.google_secret_manager_secret_version.data_secret_db_name.secret_data
    DB_USER = data.google_secret_manager_secret_version.data_secret_db_user.secret_data
    DB_PASS = data.google_secret_manager_secret_version.data_secret_db_pass.secret_data
  }
}

# Create service account for Cloud Function
resource "google_service_account" "cf_service_account" {
  account_id   = var.cf_sa_id
  display_name = var.cf_sa_name
}

# IAM entry for a single user to invoke the function
resource "google_cloudfunctions_function_iam_member" "invoker" {
  project        = var.project_id
  region         = var.region
  cloud_function = google_cloudfunctions_function.delete_posts_function.name

  role   = "roles/cloudfunctions.invoker"
  member = "serviceAccount:${google_service_account.cf_service_account.email}"
}

# Add Cloud Scheduler
resource "google_cloud_scheduler_job" "scheduler_job" {
  name             = var.scheduler_name
  description      = var.scheduler_description
  schedule         = var.scheduler_schedule
  time_zone        = var.scheduler_time_zone
  attempt_deadline = "320s"

  http_target {
    http_method = "GET"
    uri         = google_cloudfunctions_function.delete_posts_function.https_trigger_url

    oidc_token {
      service_account_email = google_service_account.cf_service_account.email
    }
  }
}
