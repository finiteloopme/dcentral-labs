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

variable "cluster_name" {
  description = "Name of the cluster"
  type = string
  default = "gke-somnia-network"
}

variable "pubsub_topic_name" {
  description = "Topic name where generated json objects should be streamed"
  default = "msg-stream"
}

variable "network_id" {
  description = "value for network id"
  default = "default"
}