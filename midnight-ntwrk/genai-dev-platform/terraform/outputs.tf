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

# ===========================================
# GKE CLUSTER
# ===========================================

output "gke_cluster_name" {
  description = "Name of the GKE Autopilot cluster"
  value       = module.gke_cluster.cluster_name
}

output "gke_namespace" {
  description = "Kubernetes namespace for midnight services"
  value       = module.midnight_k8s_services.namespace
}

output "kubectl_config_command" {
  description = "Command to configure kubectl for the GKE cluster"
  value       = module.gke_cluster.kubectl_config_command
}

# ===========================================
# MIDNIGHT SERVICE URLS
# ===========================================

output "midnight_node_url" {
  description = "Internal URL of the Midnight node service"
  value       = module.midnight_k8s_services.node_url
}

output "proof_server_url" {
  description = "Internal URL of the proof server service"
  value       = module.midnight_k8s_services.proof_server_url
}

output "indexer_url" {
  description = "Internal URL of the indexer service"
  value       = module.midnight_k8s_services.indexer_url
}

output "service_urls" {
  description = "All service URLs for environment configuration"
  value = {
    midnight_node = module.midnight_k8s_services.node_url
    proof_server  = module.midnight_k8s_services.proof_server_url
    indexer       = module.midnight_k8s_services.indexer_url
  }
}

# ===========================================
# SERVICE IPS (for reference)
# ===========================================

output "midnight_node_ip" {
  description = "Internal IP of the Midnight node service"
  value       = module.midnight_k8s_services.node_ip
}

output "proof_server_ip" {
  description = "Internal IP of the proof server service"
  value       = module.midnight_k8s_services.proof_server_ip
}

output "indexer_ip" {
  description = "Internal IP of the indexer service"
  value       = module.midnight_k8s_services.indexer_ip
}
