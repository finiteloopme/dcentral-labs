# Terraform Outputs

# ===========================================
# ARTIFACT REGISTRY
# ===========================================

output "artifact_registry_url" {
  description = "URL of the Artifact Registry repository"
  value       = module.artifact_registry.repository_url
}

# ===========================================
# WORKSTATIONS
# ===========================================

output "workstation_cluster_name" {
  description = "Name of the Cloud Workstation cluster"
  value       = module.workstations.cluster_name
}

output "workstation_config_name" {
  description = "Name of the Cloud Workstation configuration"
  value       = module.workstations.config_name
}

output "workstation_instances" {
  description = "Created workstation instances with access URLs"
  value       = module.workstations.workstation_instances
}

output "workstation_urls" {
  description = "Direct IDE URLs for all workstations"
  value       = module.workstations.workstation_urls
}

output "workstation_service_account" {
  description = "Service account used by workstation VMs"
  value       = module.workstations.service_account_email
}

# ===========================================
# GKE CLUSTER
# ===========================================

output "gke_cluster_name" {
  description = "Name of the GKE Autopilot cluster"
  value       = module.gke_cluster.cluster_name
}

output "gke_namespace" {
  description = "Kubernetes namespace for midnight services"
  value       = "midnight-services"
}

output "kubectl_config_command" {
  description = "Command to configure kubectl for the GKE cluster"
  value       = module.gke_cluster.kubectl_config_command
}

# ===========================================
# MIDNIGHT SERVICE URLS
# ===========================================

output "midnight_node_url" {
  description = "URL of the Midnight node service"
  value       = "ws://${data.kubernetes_service_v1.midnight_node.status[0].load_balancer[0].ingress[0].ip}:9944"
}

output "proof_server_url" {
  description = "URL of the proof server service"
  value       = "http://${data.kubernetes_service_v1.proof_server.status[0].load_balancer[0].ingress[0].ip}:6300"
}

output "indexer_url" {
  description = "URL of the indexer service"
  value       = "http://${data.kubernetes_service_v1.indexer.status[0].load_balancer[0].ingress[0].ip}:8088"
}

output "service_urls" {
  description = "All service URLs for environment configuration"
  value = {
    midnight_node = "ws://${data.kubernetes_service_v1.midnight_node.status[0].load_balancer[0].ingress[0].ip}:9944"
    proof_server  = "http://${data.kubernetes_service_v1.proof_server.status[0].load_balancer[0].ingress[0].ip}:6300"
    indexer       = "http://${data.kubernetes_service_v1.indexer.status[0].load_balancer[0].ingress[0].ip}:8088"
  }
}

# ===========================================
# SERVICE IPS (for reference)
# ===========================================

output "midnight_node_ip" {
  description = "IP of the Midnight node service"
  value       = data.kubernetes_service_v1.midnight_node.status[0].load_balancer[0].ingress[0].ip
}

output "proof_server_ip" {
  description = "IP of the proof server service"
  value       = data.kubernetes_service_v1.proof_server.status[0].load_balancer[0].ingress[0].ip
}

output "indexer_ip" {
  description = "IP of the indexer service"
  value       = data.kubernetes_service_v1.indexer.status[0].load_balancer[0].ingress[0].ip
}
