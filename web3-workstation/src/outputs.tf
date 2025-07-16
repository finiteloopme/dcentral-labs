// -----------------------------------------------------------------------------
// outputs.tf - Define output values
// -----------------------------------------------------------------------------

output "artifact_registry_repository_url" {
    description = "The URL of the created Artifact Registry repository."
    value       = "${var.region}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.custom_images_repo.repository_id}"
}

output "custom_docker_image_uri" {
    description = "The full URI for your custom Docker image. Build and push your image to this URI."
    value       = local.custom_image_uri
}

output "workstation_cluster_name" {
    description = "The name of the created Workstation Cluster."
    value       = google_workstations_workstation_cluster.default.name
}

output "workstation_config_name" {
    description = "The name of the created Workstation Configuration."
    value       = google_workstations_workstation_config.custom_dev_env.name
}

output "workstation_name" {
    description = "The name of the created Workstation instance."
    value       = google_workstations_workstation.developer_workstation.name
}

output "workstation_hostname" {
    description = "The hostname of the created Workstation instance (available after it's running)."
    value       = google_workstations_workstation.developer_workstation.host
}

output "workstation_launch_command" {
    description = "Command to launch the workstation using gcloud (after it's started)."
    value       = "gcloud workstations start --project=${var.project_id} --region=${var.region} --cluster=${google_workstations_workstation_cluster.default.workstation_cluster_id} --config=${google_workstations_workstation_config.custom_dev_env.workstation_config_id} ${google_workstations_workstation.developer_workstation.workstation_id} && gcloud workstations launch --project=${var.project_id} --region=${var.region} --cluster=${google_workstations_workstation_cluster.default.workstation_cluster_id} --config=${google_workstations_workstation_config.custom_dev_env.workstation_config_id} ${google_workstations_workstation.developer_workstation.workstation_id}"
}

output "workstation_port_forward_command_remix" {
    description = "Command to forward port 8080 for Remix IDE (replace YOUR_LOCAL_PORT if needed)."
    value       = "gcloud beta workstations start-tcp-tunnel --project=${var.project_id} --region=${var.region} --cluster=${google_workstations_workstation_cluster.default.workstation_cluster_id} --config=${google_workstations_workstation_config.custom_dev_env.workstation_config_id} --workstation=${google_workstations_workstation.developer_workstation.workstation_id} --local-host-port=localhost:8080 --workstation-port=8080"
}
