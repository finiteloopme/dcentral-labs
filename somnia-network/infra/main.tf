# Manage APIs
module "manage-project-services" {
  source = "./apis"
  project_id = var.project_id
  project_apis = local.project_apis
}

# Select the default network
module "default-network" {
  source = "./network"
  network_id = var.network_id
  gcp_region = var.gcp_region
  project_id = module.manage-project-services.project_id
}

# Create a GCE instance to host Somnia node
module "gce_instance" {
  source = "./gce"
  project_id = module.manage-project-services.project_id
  gcp_zone = local.gcp_zone
  subnetwork_link = module.default-network.subnetwork_link
  network_link = module.default-network.network_link
}

# Create GKE cluster to host Somnia node
# module "gke_clusters" {
#   source = "./gke"
#   project_id = module.manage-project-services.project_id
#   cluster_name = var.cluster_name
#   region = var.gcp_region
#   network = module.default-network.network_link

#   depends_on = [ module.manage-project-services ]
# }


