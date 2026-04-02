# -----------------------------------------------------------------------------
# Networking module
# - Firewall rules for health check probes and app traffic
# - Reserved global static IP for the load balancer
# -----------------------------------------------------------------------------

# Allow Google health check probes to reach the app port
resource "google_compute_firewall" "allow_health_check" {
  name    = "${var.app_name}-allow-health-check"
  project = var.project_id
  network = var.network

  allow {
    protocol = "tcp"
    ports    = [tostring(var.app_port)]
  }

  # Google Cloud health check probe source ranges
  source_ranges = [
    "130.211.0.0/22",
    "35.191.0.0/16",
  ]

  target_tags = [var.app_name]
}

# Allow IAP SSH access (debug environment only)
resource "google_compute_firewall" "allow_iap_ssh" {
  count = var.environment == "debug" ? 1 : 0

  name    = "${var.app_name}-allow-iap-ssh"
  project = var.project_id
  network = var.network

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  # IAP forwarding source range
  source_ranges = ["35.235.240.0/20"]
  target_tags   = [var.app_name]
}

# Reserved global external IP for the HTTP load balancer
resource "google_compute_global_address" "lb_ip" {
  name    = "${var.app_name}-lb-ip"
  project = var.project_id
}
