# resource "google_kms_key_ring" "keyring" {
#   name     = "eth-rbuilder"
#   location = "global"
# }

# resource "google_kms_crypto_key" "default-key" {
#   name            = "default-sym-key"
#   key_ring        = google_kms_key_ring.keyring.id
#   rotation_period = "7776000s"

#   lifecycle {
#     prevent_destroy = true
#   }
# }