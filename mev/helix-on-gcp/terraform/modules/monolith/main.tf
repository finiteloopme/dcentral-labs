variable "project_id" {}
variable "region" {}
variable "subnet_link" {}
variable "image_tag" {}

resource "google_compute_instance" "monolith" {
  name         = "helix-monolith"
  machine_type = "c2-standard-16"
  zone         = "${var.region}-a"

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2204-lts"
    }
  }

  scratch_disk { interface = "NVME" } # Local SSD

  network_interface {
    subnetwork = var.subnet_link
    access_config {}
  }

  # Startup script configures RAID0, Docker, and runs the stack
  metadata_startup_script = <<-EOF
    #!/bin/bash
    set -e
    
    # 1. Mount Local SSD
    mkfs.ext4 -F /dev/nvme0n1
    mkdir -p /mnt/data
    mount /dev/nvme0n1 /mnt/data
    
    # 2. Setup Docker
    curl -fsSL https://get.docker.com -o get-docker.sh
    sh get-docker.sh
    gcloud auth configure-docker gcr.io -q
    
    # 3. Configure Config File
    mkdir -p /mnt/data/helix
    cat <<TOML > /mnt/data/helix/config.toml
    [database]
    url = "postgres://postgres:password@postgres:5432/helix"
    [redis]
    url = "redis://redis:6379"
    [http]
    host = "0.0.0.0"
    port = 18550
    TOML
    
    # 4. Run Monolithic Container Stack (DB + Redis + App)
    docker network create helix-net
    
    # DB (Data on NVMe)
    docker run -d --name postgres --net helix-net \
      -v /mnt/data/postgres:/var/lib/postgresql/data \
      -e POSTGRES_PASSWORD=password \
      -e POSTGRES_DB=helix \
      postgres:15-alpine
      
    # Redis
    docker run -d --name redis --net helix-net redis:7-alpine
    
    # Helix App
    docker run -d --name helix --net helix-net \
      -v /mnt/data/helix/config.toml:/etc/helix/config.toml \
      -p 18550:18550 \
      ${image_tag} --config /etc/helix/config.toml
  EOF
  
  tags = ["helix-monolith"]
}
