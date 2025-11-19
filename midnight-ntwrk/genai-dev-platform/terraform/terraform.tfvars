# Terraform Variables Configuration
# Midnight Development Platform

# Required variables
project_id  = "kunal-scratch"
region      = "us-central1"
zone        = "us-central1-a"
environment = "dev"

# Workstation configuration
workstation_config = {
  machine_type            = "n2-standard-8"
  boot_disk_size_gb       = 50
  persistent_disk_size_gb = 200
  idle_timeout            = "1200s"  # 20 minutes
  running_timeout         = "14400s" # 4 hours
}

# Multiple workstations with associated users
workstations = {
  "jenna-workstation" = {
    user = "admin@kunall.altostrat.com"
  }
  "karmel-workstation" = {
    user = "admin@kunall.altostrat.com"
  }
  "bob-workstation" = {
    user = "admin@kunall.altostrat.com"
  }
  "ben-workstation" = {
    user = "admin@kunall.altostrat.com"
  }
  "scott-workstation" = {
    user = "admin@kunall.altostrat.com"
  }
  "rich-workstation" = {
    user = "admin@kunall.altostrat.com"
  }
  "kyle-workstation" = {
    user = "admin@kunall.altostrat.com"
  }
  "kunal-workstation" = {
    user = "admin@kunall.altostrat.com"
  }
}

# Custom domain configuration (optional)
enable_custom_domain = false
custom_domain        = ""
custom_domain_ip     = ""

# Additional DNS records (optional)
additional_dns_records = []

# State bucket configuration
state_bucket_name     = ""
state_bucket_location = "US"