# main.tf

terraform {
  backend "gcs" {
    prefix = "terraform/state/reth-node"
  }
}

# --- GCP Provider Configuration ---
provider "google" {
  project = var.gcp_project_id
  region  = var.gcp_region
  zone    = var.gcp_zone
  impersonate_service_account = "tf-service-account@kunal-scratch.iam.gserviceaccount.com"
}

# --- Networking ---
resource "google_compute_network" "vpc_network" {
  name                    = "reth-vpc"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "vpc_subnetwork" {
  name          = "reth-subnet"
  ip_cidr_range = "10.10.0.0/24"
  network       = google_compute_network.vpc_network.id
  region        = var.gcp_region
}

resource "google_compute_firewall" "allow_ssh_http" {
  name    = "reth-firewall"
  network = google_compute_network.vpc_network.name
  allow {
    protocol = "tcp"
    ports    = ["22", "8545", "8546", "30303"]
  }
  source_ranges = ["0.0.0.0/0"] # For simplicity; restrict in production
}

# --- Data Disk ---
# This resource creates the large disk for storing chain data.
# It can be created from a pre-existing snapshot for fast deployments,
# or as a new empty disk for the initial setup.
resource "google_compute_disk" "reth_data_disk" {
  name     = "reth-chain-data-disk"
  type     = "hyperdisk-extreme"
  zone     = var.gcp_zone
  # Conditionally create from snapshot if a name is provided.
  snapshot = var.gcp_disk_snapshot_name != "" ? var.gcp_disk_snapshot_name : null
  # If no snapshot, create a new 2.5TB empty disk.
  size     = var.gcp_disk_snapshot_name != "" ? null : 4000

  # Ensure the disk is deleted when the instance is destroyed.
  labels = {
    "created-by" = "terraform"
  }
}


# --- Compute Instance ---
resource "google_compute_instance" "reth_node" {
  name         = "reth-private-fork-node"
  machine_type = var.machine_type
  zone         = var.gcp_zone

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2204-lts"
      size  = 200 # GB
    }
  }

  attached_disk {
    source      = google_compute_disk.reth_data_disk.id
    device_name = "reth-data-disk"
  }

  network_interface {
    subnetwork = google_compute_subnetwork.vpc_subnetwork.id
    access_config {
      // Ephemeral public IP
    }
  }

  metadata = {
    "startup-script" = file("startup_script.sh")
    "genesis-json"   = file("private-genesis.json")
  }

  service_account {
    scopes = ["cloud-platform"]
  }

  allow_stopping_for_update = true
}
