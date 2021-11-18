terraform {
  backend "gcs" {
    bucket = "${var.project_id}-tfstate"
    prefix = ""
  }
  required_version = ">= 1.0.10"
}

provider "google" {
  project = var.project_id
  reigon = var.region
  zone = var.zone
  #credentials = file("./terraform-sa.json")
}

provider "google-beta" {
  project = var.project_id
  region = var.region
  zone = var.zone
  #credentials = file("./terraform-sa.json")
}

provider "null" {
}
