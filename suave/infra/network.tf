resource "google_compute_network" "suave-network" {
  auto_create_subnetworks = false
  mtu                     = 1460
  name                    = "suave-network"
  project                 = var.project_id
  routing_mode            = "REGIONAL"
}

resource "google_compute_subnetwork" "suave-subnets" {
  for_each = local.subnets
  name          = each.value.name
  ip_cidr_range = each.value.cidr
  region        = each.value.region

  network       = google_compute_network.suave-network.id
}

data "google_compute_subnetwork" "suave-default-subnet" {
  name   = var.gcp_region
  region = var.gcp_region

  depends_on = [ google_compute_subnetwork.suave-subnets ]
}