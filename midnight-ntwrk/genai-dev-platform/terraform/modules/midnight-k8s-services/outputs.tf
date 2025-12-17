# Midnight Kubernetes Services Module Outputs

output "namespace" {
  description = "Kubernetes namespace for midnight services"
  value       = kubernetes_namespace_v1.midnight_services.metadata[0].name
}

# ===========================================
# SERVICE URLS (Internal Load Balancer IPs)
# ===========================================

output "node_url" {
  description = "Internal URL of the Midnight node service"
  value       = "ws://${kubernetes_service_v1.midnight_node.status[0].load_balancer[0].ingress[0].ip}:9944"
}

output "proof_server_url" {
  description = "Internal URL of the proof server service"
  value       = "http://${kubernetes_service_v1.proof_server.status[0].load_balancer[0].ingress[0].ip}:6300"
}

output "indexer_url" {
  description = "Internal URL of the indexer service"
  value       = "http://${kubernetes_service_v1.indexer.status[0].load_balancer[0].ingress[0].ip}:8088"
}

# ===========================================
# SERVICE IPs (for reference)
# ===========================================

output "node_ip" {
  description = "Internal IP of the Midnight node service"
  value       = kubernetes_service_v1.midnight_node.status[0].load_balancer[0].ingress[0].ip
}

output "proof_server_ip" {
  description = "Internal IP of the proof server service"
  value       = kubernetes_service_v1.proof_server.status[0].load_balancer[0].ingress[0].ip
}

output "indexer_ip" {
  description = "Internal IP of the indexer service"
  value       = kubernetes_service_v1.indexer.status[0].load_balancer[0].ingress[0].ip
}
