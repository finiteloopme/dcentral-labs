# -----------------------------------------------------------------------------
# Load Balancer module
# - Backend service
# - URL map
# - Target HTTP proxy
# - Global forwarding rule
#
# NOTE: The health check is defined at the root level and passed in via
#       var.health_check_id to avoid a circular dependency with the compute
#       module (compute needs the health check for auto-healing, lb needs
#       the MIG instance group for the backend).
# -----------------------------------------------------------------------------

# ---------------------------------------------------------------------------
# Backend Service
# ---------------------------------------------------------------------------
resource "google_compute_backend_service" "default" {
  name        = "${var.app_name}-backend"
  project     = var.project_id
  protocol    = "HTTP"
  port_name   = "http"
  timeout_sec = 30

  health_checks = [var.health_check_id]

  backend {
    group           = var.instance_group
    balancing_mode  = "UTILIZATION"
    max_utilization = 0.8
  }

  log_config {
    enable      = true
    sample_rate = 1.0
  }
}

# ---------------------------------------------------------------------------
# URL Map
# ---------------------------------------------------------------------------
resource "google_compute_url_map" "default" {
  name            = "${var.app_name}-url-map"
  project         = var.project_id
  default_service = google_compute_backend_service.default.id
}

# ---------------------------------------------------------------------------
# Target HTTP Proxy
# ---------------------------------------------------------------------------
resource "google_compute_target_http_proxy" "default" {
  name    = "${var.app_name}-http-proxy"
  project = var.project_id
  url_map = google_compute_url_map.default.id
}

# ---------------------------------------------------------------------------
# Global Forwarding Rule
# ---------------------------------------------------------------------------
resource "google_compute_global_forwarding_rule" "default" {
  name       = "${var.app_name}-forwarding-rule"
  project    = var.project_id
  target     = google_compute_target_http_proxy.default.id
  ip_address = var.lb_ip_address
  port_range = "80"
}
