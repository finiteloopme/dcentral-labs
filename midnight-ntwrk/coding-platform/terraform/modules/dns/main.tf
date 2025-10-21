# Cloud DNS Zone
resource "google_dns_managed_zone" "workstation_zone" {
  count = var.enable_dns ? 1 : 0

  name        = var.dns_zone_name != "" ? var.dns_zone_name : "midnight-${var.environment}-zone"
  dns_name    = "${var.domain_name}."
  description = "DNS zone for Midnight ${var.environment} workstations"
  project     = var.project_id

  labels = {
    environment = var.environment
    managed_by  = "terraform"
  }

  dnssec_config {
    state = "on"
  }
}

# A record for workstation access
resource "google_dns_record_set" "workstation_a_record" {
  count = var.enable_dns && var.workstation_ip != "" ? 1 : 0

  name         = google_dns_managed_zone.workstation_zone[0].dns_name
  type         = "A"
  ttl          = 300
  managed_zone = google_dns_managed_zone.workstation_zone[0].name
  project      = var.project_id
  rrdatas      = [var.workstation_ip]
}

# Wildcard record for subdomain access (e.g., *.midnight-dev.example.com)
resource "google_dns_record_set" "workstation_wildcard_record" {
  count = var.enable_dns && var.workstation_ip != "" ? 1 : 0

  name         = "*.${google_dns_managed_zone.workstation_zone[0].dns_name}"
  type         = "A"
  ttl          = 300
  managed_zone = google_dns_managed_zone.workstation_zone[0].name
  project      = var.project_id
  rrdatas      = [var.workstation_ip]
}

# CNAME for specific workstation names
resource "google_dns_record_set" "workstation_cname" {
  for_each = var.enable_dns ? {
    "workstation" = "workstation",
    "dev"         = "dev",
    "ide"         = "ide",
    "code"        = "code"
  } : {}

  name         = "${each.value}.${google_dns_managed_zone.workstation_zone[0].dns_name}"
  type         = "CNAME"
  ttl          = 300
  managed_zone = google_dns_managed_zone.workstation_zone[0].name
  project      = var.project_id
  rrdatas      = [google_dns_managed_zone.workstation_zone[0].dns_name]
}

# Additional custom DNS records
resource "google_dns_record_set" "custom_records" {
  for_each = var.enable_dns ? { for r in var.dns_records : "${r.name}-${r.type}" => r } : {}

  name         = "${each.value.name}.${google_dns_managed_zone.workstation_zone[0].dns_name}"
  type         = each.value.type
  ttl          = each.value.ttl
  managed_zone = google_dns_managed_zone.workstation_zone[0].name
  project      = var.project_id
  rrdatas      = each.value.data
}