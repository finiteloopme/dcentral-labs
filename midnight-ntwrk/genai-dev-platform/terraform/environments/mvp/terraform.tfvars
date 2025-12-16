# MVP Environment Configuration

environment = "mvp"
region      = "us-central1"
zone        = "us-central1-a"

# Workstation configuration for MVP
workstation_config = {
  machine_type            = "e2-standard-4" # 4 vCPU, 16 GB RAM
  boot_disk_size_gb       = 50
  persistent_disk_size_gb = 200
  idle_timeout            = "1200s"  # 20 minutes
  running_timeout         = "14400s" # 4 hours
}