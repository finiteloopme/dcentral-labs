output "backend_service_id" {
  description = "ID of the backend service"
  value       = google_compute_backend_service.default.id
}
