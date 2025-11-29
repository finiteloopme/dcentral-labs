variable "project_id" {}
variable "region" {}

resource "google_compute_network" "vpc" {
  name                    = "helix-vpc"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "subnet" {
  name          = "helix-subnet"
  ip_cidr_range = "10.0.0.0/24"
  region        = var.region
  network       = google_compute_network.vpc.id
}

# Private Service Access (Required for Cloud SQL / Redis Peering)
resource "google_compute_global_address" "private_ip_range" {
  name          = "helix-private-ip"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = google_compute_network.vpc.id
}

resource "google_service_networking_connection" "private_vpc_connection" {
  network                 = google_compute_network.vpc.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip_range.name]
}

resource "google_compute_firewall" "allow_internal" {
  name    = "helix-allow-internal"
  network = google_compute_network.vpc.name
  allow {
    protocol = "tcp"
  }
  source_ranges = ["10.0.0.0/8"]
}

# Allow SSH from IAP/External (For Attacker VM access)
resource "google_compute_firewall" "allow_ssh" {
  name    = "helix-allow-ssh"
  network = google_compute_network.vpc.name
  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
  source_ranges = ["0.0.0.0/0"] 
}

output "vpc_id" { value = google_compute_network.vpc.id }
output "vpc_self_link" { value = google_compute_network.vpc.self_link }
output "subnet_self_link" { value = google_compute_subnetwork.subnet.self_link }
