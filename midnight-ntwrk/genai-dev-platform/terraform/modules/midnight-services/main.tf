# Midnight Services Module
#
# Deploys Cloud Run services for the Midnight standalone network:
# - midnight-node: Blockchain node
# - proof-server: Zero-knowledge proof generation
# - indexer: Blockchain indexer with PostgreSQL sidecar

# ===========================================
# MIDNIGHT NODE
# ===========================================

resource "google_cloud_run_v2_service" "midnight_node" {
  provider = google-beta

  project  = var.project_id
  location = var.region
  name     = "midnight-node-${var.cluster_name}"
  labels   = var.labels

  template {
    labels = var.labels

    scaling {
      min_instance_count = var.min_instances
      max_instance_count = 1  # Single node for standalone
    }

    containers {
      image = var.midnight_node_image
      
      args = [
        "--chain=standalone",
        "--alice",
        "--tmp",
        "--ws-external",
        "--rpc-cors=all",
        "--rpc-external",
      ]

      ports {
        container_port = 9944
      }

      resources {
        limits = {
          cpu    = "2"
          memory = "4Gi"
        }
      }

      # Startup probe - node takes time to initialize
      startup_probe {
        http_get {
          path = "/health"
          port = 9944
        }
        initial_delay_seconds = 10
        timeout_seconds       = 5
        period_seconds        = 10
        failure_threshold     = 30
      }
    }

    # Allow longer request timeout for WebSocket
    timeout = "3600s"
  }

  # Allow unauthenticated for now (WebSocket connections)
  # TODO: Consider adding authentication layer
}

# IAM: Allow workstation to invoke
resource "google_cloud_run_v2_service_iam_member" "node_invoker" {
  provider = google-beta

  project  = var.project_id
  location = var.region
  name     = google_cloud_run_v2_service.midnight_node.name
  role     = "roles/run.invoker"
  member   = "serviceAccount:${var.workstation_service_account}"
}

# Allow all users (for WebSocket support)
resource "google_cloud_run_v2_service_iam_member" "node_public" {
  provider = google-beta

  project  = var.project_id
  location = var.region
  name     = google_cloud_run_v2_service.midnight_node.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}

# ===========================================
# PROOF SERVER
# ===========================================

resource "google_cloud_run_v2_service" "proof_server" {
  provider = google-beta

  project  = var.project_id
  location = var.region
  name     = "proof-server-${var.cluster_name}"
  labels   = var.labels

  template {
    labels = var.labels

    scaling {
      min_instance_count = var.min_instances
      max_instance_count = 2
    }

    containers {
      image   = var.proof_server_image
      command = ["midnight-proof-server"]
      args    = ["--network", "standalone"]

      ports {
        container_port = 6300
      }

      resources {
        limits = {
          cpu    = "4"
          memory = "8Gi"
        }
      }

      startup_probe {
        http_get {
          path = "/health"
          port = 6300
        }
        initial_delay_seconds = 5
        timeout_seconds       = 5
        period_seconds        = 10
        failure_threshold     = 20
      }
    }

    timeout = "900s"  # Proofs can take time
  }
}

# IAM: Allow workstation to invoke
resource "google_cloud_run_v2_service_iam_member" "proof_invoker" {
  provider = google-beta

  project  = var.project_id
  location = var.region
  name     = google_cloud_run_v2_service.proof_server.name
  role     = "roles/run.invoker"
  member   = "serviceAccount:${var.workstation_service_account}"
}

# Allow all users
resource "google_cloud_run_v2_service_iam_member" "proof_public" {
  provider = google-beta

  project  = var.project_id
  location = var.region
  name     = google_cloud_run_v2_service.proof_server.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}

# ===========================================
# INDEXER WITH POSTGRES SIDECAR
# ===========================================

resource "google_cloud_run_v2_service" "indexer" {
  provider = google-beta

  project  = var.project_id
  location = var.region
  name     = "indexer-${var.cluster_name}"
  labels   = var.labels

  template {
    labels = var.labels

    scaling {
      min_instance_count = var.min_instances
      max_instance_count = 1
    }

    # PostgreSQL sidecar container
    containers {
      name  = "postgres"
      image = "postgres:15-alpine"

      env {
        name  = "POSTGRES_PASSWORD"
        value = "midnight"
      }
      env {
        name  = "POSTGRES_DB"
        value = "midnight"
      }
      env {
        name  = "POSTGRES_USER"
        value = "midnight"
      }

      ports {
        container_port = 5432
      }

      resources {
        limits = {
          cpu    = "1"
          memory = "2Gi"
        }
      }

      startup_probe {
        tcp_socket {
          port = 5432
        }
        initial_delay_seconds = 5
        timeout_seconds       = 5
        period_seconds        = 5
        failure_threshold     = 10
      }

      # Volume for ephemeral data
      volume_mounts {
        name       = "pgdata"
        mount_path = "/var/lib/postgresql/data"
      }
    }

    # Indexer container
    containers {
      name  = "indexer"
      image = var.indexer_image

      env {
        name  = "NODE_WS"
        value = google_cloud_run_v2_service.midnight_node.uri
      }
      env {
        name  = "POSTGRES_URL"
        value = "postgres://midnight:midnight@localhost:5432/midnight"
      }

      ports {
        container_port = 8081
      }

      resources {
        limits = {
          cpu    = "2"
          memory = "4Gi"
        }
      }

      startup_probe {
        http_get {
          path = "/health"
          port = 8081
        }
        initial_delay_seconds = 15
        timeout_seconds       = 5
        period_seconds        = 10
        failure_threshold     = 30
      }

      # Depends on postgres being ready
      depends_on = ["postgres"]
    }

    # Ephemeral volume for postgres data
    volumes {
      name = "pgdata"
      empty_dir {
        medium     = "MEMORY"
        size_limit = "1Gi"
      }
    }

    timeout = "300s"
  }
}

# IAM: Allow workstation to invoke
resource "google_cloud_run_v2_service_iam_member" "indexer_invoker" {
  provider = google-beta

  project  = var.project_id
  location = var.region
  name     = google_cloud_run_v2_service.indexer.name
  role     = "roles/run.invoker"
  member   = "serviceAccount:${var.workstation_service_account}"
}

# Allow all users
resource "google_cloud_run_v2_service_iam_member" "indexer_public" {
  provider = google-beta

  project  = var.project_id
  location = var.region
  name     = google_cloud_run_v2_service.indexer.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}
