terraform {
  backend "gcs" {
    prefix = "helix-benchmark"
  }
  required_providers {
    google = { source = "hashicorp/google", version = "~> 5.0" }
    kubernetes = { source = "hashicorp/kubernetes", version = "~> 2.20" }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

# Dynamic Kubernetes Provider (Connects to the cluster created below)
data "google_client_config" "default" {}

provider "kubernetes" {
  host                   = "https://${module.cloud_native.cluster_endpoint}"
  token                  = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(module.cloud_native.cluster_ca_certificate)
}

# --- Enabled Services ---
module "services" {
  source     = "./modules/services"
  project_id = var.project_id
}

# --- Network (Shared) ---
module "network" {
  source     = "./modules/network"
  project_id = var.project_id
  region     = var.region
  depends_on = [module.services]
}

# --- Config 1: Monolith (VM + Local SSD) ---
module "monolith" {
  source      = "./modules/monolith"
  project_id  = var.project_id
  region      = var.region
  subnet_link = module.network.subnet_self_link
  image_tag   = "gcr.io/${var.project_id}/helix:benchmark"
  depends_on  = [module.services]
}

# --- Config 2: Cloud Native (GKE + Cloud SQL + Redis) ---
module "cloud_native" {
  source       = "./modules/cloud-native"
  project_id   = var.project_id
  region       = var.region
  vpc_id       = module.network.vpc_id
  vpc_link     = module.network.vpc_self_link
  subnet_link  = module.network.subnet_self_link
  image_tag    = "gcr.io/${var.project_id}/helix:benchmark"
  depends_on   = [module.services]
}

# --- Attacker (Load Generator) ---
module "attacker" {
  source      = "./modules/attacker"
  zone        = "${var.region}-a"
  subnet_link = module.network.subnet_self_link
  depends_on  = [module.services]
}
