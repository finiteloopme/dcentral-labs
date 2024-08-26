# resource "google_service_account" "el-service-account" {
#   account_id   = "reth-el-sa"
#   display_name = "Execution Layer (reth) SA"
# }

# resource "google_service_account" "cl-service-account" {
#   account_id   = "lighthouse-cl-sa"
#   display_name = "Consensus Layer (lighthouse) SA"
# }

resource "google_service_account" "rbuilder-service-account" {
  account_id   = "rbuilder-sa"
  display_name = "rBuilder SA"
}

resource "google_compute_firewall" "firewall-http-ssh" {
    name        = "fw-http-ssh"
    network     = google_compute_network.suave-network.id
    description = "Creates firewall rule to manage HTTP(s) & SSH"

    allow {
        protocol  = "tcp"
        ports     = ["22", "80", "8080", "443", "8443", "8000-10000"]
    }
    source_ranges = ["0.0.0.0/0"]
    target_tags = ["web", "ssh"]
}

# resource "google_service_account_iam_member" "el-sa-binding" {
#   service_account_id = google_service_account.el-service-account.id
#   for_each = toset(local.sa_roles)
#   role = each.key
#   member = "serviceAccount:${google_service_account.el-service-account.email}"
# }
