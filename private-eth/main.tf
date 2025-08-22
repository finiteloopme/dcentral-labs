# main.tf

# Configure Terraform to use a Google Cloud Storage (GCS) bucket for its state file.
# This is essential for CI/CD environments and team collaboration.
terraform {
  backend "gcs" {
    # The bucket name will be configured dynamically by the Cloud Build 'init' step
    # using the -backend-config flag. This avoids hardcoding the bucket name.
    prefix = "terraform/private-eth/state/reth-node"
  }
}

# Configure the Google Cloud provider
provider "google" {
  project = var.gcp_project_id
  region  = var.gcp_region
  zone    = var.gcp_zone
  impersonate_service_account = "tf-service-account@kunal-scratch.iam.gserviceaccount.com"
}

# Create a new VPC network for our resources
resource "google_compute_network" "reth_vpc" {
  name                    = "reth-vpc-network"
  auto_create_subnetworks = false # We will create a custom subnet
}

# Create a subnet in the VPC
resource "google_compute_subnetwork" "reth_subnet" {
  name          = "reth-public-subnet"
  ip_cidr_range = "10.0.1.0/24"
  network       = google_compute_network.reth_vpc.id
  region        = var.gcp_region
}

# Create firewall rules to allow necessary traffic
resource "google_compute_firewall" "reth_firewall" {
  name    = "reth-firewall-rules"
  network = google_compute_network.reth_vpc.id

  # Allow inbound SSH, Reth P2P, and RPC traffic from anywhere
  allow {
    protocol = "tcp"
    ports    = ["22", "30303", "8545"]
  }
  allow {
    protocol = "udp"
    ports    = ["30303"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["reth-node"] # Apply this rule to instances with this tag
}

# Create a large, fast persistent disk for chain data
resource "google_compute_disk" "reth_data_disk" {
  name = "reth-chain-data-disk"
  type = "pd-ssd" # Use an SSD for performance
  size = 2500     # 2.5TB in GB, adjust as needed
}

# Create a Compute Engine instance to run the Reth node
resource "google_compute_instance" "reth_node" {
  name         = "reth-private-fork-node"
  machine_type = var.machine_type
  zone         = var.gcp_zone
  tags         = ["reth-node"] # Tag for the firewall rule

  # Configure the boot disk with Ubuntu
  boot_disk {
    initialize_params {
      image = var.image
      size  = 50 # GB
    }
  }

  # Attach the large data disk
  attached_disk {
    source      = google_compute_disk.reth_data_disk.id
    device_name = "reth-data-disk" # A name for the attachment
  }


  # Configure the network interface
  network_interface {
    network    = google_compute_network.reth_vpc.id
    subnetwork = google_compute_subnetwork.reth_subnet.id
    access_config {
      // Ephemeral public IP
    }
  }

  # Pass the startup script and genesis file as instance metadata
  metadata = {
    startup-script = file("${path.module}/startup_script.sh")
    genesis_json   = file("${path.module}/private-genesis.json")
  }

  // Allow the instance to manage disks
  service_account {
    scopes = ["cloud-platform"]
  }

  // It's good practice to ensure the disk is deleted when the instance is
  lifecycle {
    ignore_changes = [attached_disk]
  }
}

# Output the public IP address of the instance
output "instance_public_ip" {
  value = google_compute_instance.reth_node.network_interface[0].access_config[0].nat_ip
}
