resource "google_compute_instance" "mock_server" {
  name         = "mock-server"
  machine_type = var.mock_server_machine_type
  zone         = "${var.gcp_region}-a"
  
  tags = [var.project_name]
  
  depends_on = [
    google_project_service.compute
  ]
  
  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }
  
  network_interface {
    subnetwork = google_compute_subnetwork.subnet.id
    network_ip = var.mock_server_ip
  }
  
  metadata = {
    ssh-keys = "user:${file(var.ssh_public_key_path)}"
  }
  
  metadata_startup_script = file("scripts/setup-mock-server.sh")
}

resource "google_compute_instance" "tee_service" {
  name         = "tee-service"
  machine_type = var.tee_service_machine_type
  zone         = "${var.gcp_region}-a"
  
  tags = [var.project_name]
  
  depends_on = [
    google_project_service.compute
  ]
  
  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }
  
  network_interface {
    subnetwork = google_compute_subnetwork.subnet.id
    network_ip = var.tee_service_ip
  }
  
  metadata = {
    ssh-keys = "user:${file(var.ssh_public_key_path)}"
    enable-confidential-computing = "true"
  }
  
  metadata_startup_script = file("scripts/setup-tee-service.sh")
}