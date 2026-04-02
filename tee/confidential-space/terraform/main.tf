# -----------------------------------------------------------------------------
# Root Terraform module for Confidential Space Hello World
# Wires together: networking, compute, and lb modules.
#
# Dependency graph (no cycles):
#   networking (independent)
#   health_check (independent)
#   compute  -> depends on networking.network_tag, health_check
#   lb       -> depends on compute.instance_group, networking.lb_ip, health_check
# -----------------------------------------------------------------------------

terraform {
  required_version = ">= 1.5"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

# ---------------------------------------------------------------------------
# Health Check (defined at root level to avoid circular dependency
# between compute and lb modules)
# ---------------------------------------------------------------------------
resource "google_compute_health_check" "http" {
  name    = "${var.app_name}-health-check"
  project = var.project_id

  check_interval_sec  = 10
  timeout_sec         = 5
  healthy_threshold   = 2
  unhealthy_threshold = 3

  http_health_check {
    port         = var.app_port
    request_path = "/health"
  }
}

# ---------------------------------------------------------------------------
# Networking: firewall rules + reserved LB IP
# ---------------------------------------------------------------------------
module "networking" {
  source = "./modules/networking"

  project_id  = var.project_id
  app_name    = var.app_name
  app_port    = var.app_port
  environment = var.environment
}

# ---------------------------------------------------------------------------
# Compute: service account, instance template, MIG, autoscaler
# ---------------------------------------------------------------------------
module "compute" {
  source = "./modules/compute"

  project_id        = var.project_id
  region            = var.region
  zone              = var.zone
  app_name          = var.app_name
  app_port          = var.app_port
  machine_type      = var.machine_type
  confidential_type = var.confidential_type
  image_family      = var.image_family
  docker_image      = var.docker_image
  environment       = var.environment
  mig_min_replicas  = var.mig_min_replicas
  mig_max_replicas  = var.mig_max_replicas
  network_tag       = module.networking.network_tag
  health_check_id   = google_compute_health_check.http.self_link
}

# ---------------------------------------------------------------------------
# Load Balancer: backend service, URL map, proxy, forwarding rule
# ---------------------------------------------------------------------------
module "lb" {
  source = "./modules/lb"

  project_id      = var.project_id
  app_name        = var.app_name
  health_check_id = google_compute_health_check.http.id
  instance_group  = module.compute.instance_group
  lb_ip_address   = module.networking.lb_ip_self_link
}
