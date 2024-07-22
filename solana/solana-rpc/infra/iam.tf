resource "google_service_account" "solana_etl" {
  account_id   = "solana-sa"
  display_name = "Solana Service Account"
  project      = var.project_id
}

resource "google_project_iam_member" "service_account_roles" {
  for_each = toset(local.sa_roles)

  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.solana_etl.email}"
}