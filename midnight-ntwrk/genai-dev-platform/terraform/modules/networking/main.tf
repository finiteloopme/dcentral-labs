# VPC Network
resource "google_compute_network" "vpc" {
  name                    = "midnight-${var.environment}-vpc"
  auto_create_subnetworks = false
  project                 = var.project_id
}

# Subnet
resource "google_compute_subnetwork" "workstation_subnet" {
  name          = "midnight-${var.environment}-workstation-subnet"
  ip_cidr_range = var.ip_cidr_range
  region        = var.region
  network       = google_compute_network.vpc.id
  project       = var.project_id

  private_ip_google_access = true

  log_config {
    aggregation_interval = "INTERVAL_5_SEC"
    flow_sampling        = 0.5
    metadata             = "INCLUDE_ALL_METADATA"
  }
}

# Cloud Router
resource "google_compute_router" "router" {
  name    = "midnight-${var.environment}-router"
  region  = var.region
  network = google_compute_network.vpc.id
  project = var.project_id
}

# NAT Gateway
resource "google_compute_router_nat" "nat" {
  name                               = "midnight-${var.environment}-nat"
  router                             = google_compute_router.router.name
  region                             = var.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
  project                            = var.project_id

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}

# Firewall rules
resource "google_compute_firewall" "allow_iap" {
  name    = "midnight-${var.environment}-allow-iap"
  network = google_compute_network.vpc.name
  project = var.project_id

  allow {
    protocol = "tcp"
    ports    = ["22", "3389"]
  }

  source_ranges = ["35.235.240.0/20"]
  direction     = "INGRESS"
  priority      = 1000
}

resource "google_compute_firewall" "allow_internal" {
  name    = "midnight-${var.environment}-allow-internal"
  network = google_compute_network.vpc.name
  project = var.project_id

  allow {
    protocol = "tcp"
    ports    = ["0-65535"]
  }

  allow {
    protocol = "udp"
    ports    = ["0-65535"]
  }

  allow {
    protocol = "icmp"
  }

  source_ranges = [var.ip_cidr_range]
  direction     = "INGRESS"
  priority      = 1000
}

# Reserve a static external IP for NAT
resource "google_compute_address" "nat_ip" {
  name    = "midnight-${var.environment}-nat-ip"
  project = var.project_id
  region  = var.region
}
