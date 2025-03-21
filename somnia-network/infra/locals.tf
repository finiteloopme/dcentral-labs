locals {

  # API services
  project_apis = [
        "compute.googleapis.com",
        "container.googleapis.com",
        "cloudresourcemanager.googleapis.com",
        "pubsub.googleapis.com",
        "dataflow.googleapis.com",
        # Enabling the ServiceUsage API allows the new project to be quota checked from now on.
        "serviceusage.googleapis.com",
        "logging.googleapis.com",
  ]

  # Default zone to use
  gcp_zone = "${var.gcp_region}-a"

}