variable "project_id" {
  description = "ID for the project"
}

variable "gcp_region" {
  description = "GCP Region"
  default = "us-central1"
}

variable "app_name" {
  description = "Name of the application"
  default = "sample-gcp-app"
}

variable "subnets" {
  type = list(object({
    name = string
    cidr = string
    region = string
  }))
  default = [ {
    name = "us-central1"
    cidr = "10.1.0.0/16"
    region = "us-central1"
    }, 
    {
    name = "us-west1"
    cidr = "10.2.0.0/16"
    region = "us-west1"
    }, 
  ]
}