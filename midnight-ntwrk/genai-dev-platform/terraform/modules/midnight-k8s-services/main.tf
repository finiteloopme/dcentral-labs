# Midnight Kubernetes Services Module
#
# Deploys Midnight standalone services to an existing GKE cluster:
# - midnight-node: Blockchain node (StatefulSet with External LB)
# - proof-server: Zero-knowledge proof generation (Deployment with External LB)
# - indexer: Blockchain indexer using SQLite (StatefulSet with External LB)
#
# Component Versions (as of 0.18.0 upgrade):
# - Node: midnightntwrk/midnight-node:0.18.0
# - Proof Server: midnightnetwork/proof-server:6.2.0-rc.2
# - Indexer: midnightntwrk/indexer-standalone:3.0.0-alpha.20
#
# Key Configuration Notes:
# - Node 0.18.0 requires USE_MAIN_CHAIN_FOLLOWER_MOCK=true for dev mode
# - Indexer 3.x uses ConfigMap for config (API endpoint: /api/v3/graphql)
#
# Prerequisites: GKE cluster must exist and Kubernetes provider must be configured.

terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 3.0"
    }
  }
}

# ===========================================
# LOCALS - Chain environment mappings
# ===========================================

locals {
  # Is this a dev/standalone environment?
  is_dev_mode = var.chain_environment == "standalone"
}

# ===========================================
# KUBERNETES NAMESPACE
# ===========================================

resource "kubernetes_namespace_v1" "midnight_services" {
  metadata {
    name = "midnight-services"
    labels = merge(var.labels, {
      "app.kubernetes.io/name" = "midnight-services"
    })
  }
}

# ===========================================
# MIDNIGHT NODE - StatefulSet + External LB
# ===========================================

resource "kubernetes_stateful_set_v1" "midnight_node" {
  metadata {
    name      = "midnight-node"
    namespace = kubernetes_namespace_v1.midnight_services.metadata[0].name
    labels = {
      app = "midnight-node"
    }
  }

  spec {
    service_name = "midnight-node"
    replicas     = 1

    selector {
      match_labels = {
        app = "midnight-node"
      }
    }

    template {
      metadata {
        labels = merge(var.labels, {
          app = "midnight-node"
        })
      }

      spec {
        container {
          name  = "midnight-node"
          image = var.midnight_node_image

          # Command args for dev mode (required for 0.18.0+)
          args = local.is_dev_mode ? [
            "--dev",
            "--rpc-external",
            "--rpc-cors=all",
            "--rpc-methods=unsafe"
          ] : []

          # Required for 0.18.0 dev mode - mock the Cardano chain follower
          dynamic "env" {
            for_each = local.is_dev_mode ? [1] : []
            content {
              name  = "USE_MAIN_CHAIN_FOLLOWER_MOCK"
              value = "true"
            }
          }

          dynamic "env" {
            for_each = local.is_dev_mode ? [1] : []
            content {
              name  = "MOCK_REGISTRATIONS_FILE"
              value = "res/mock-bridge-data/default-registrations.json"
            }
          }

          # Block beneficiary address for dev mode block rewards
          env {
            name  = "SIDECHAIN_BLOCK_BENEFICIARY"
            value = "04bcf7ad3be7a5c790460be82a713af570f22e0f801f6659ab8e84a52be6969e"
          }

          port {
            container_port = 9944
            name           = "rpc"
          }

          resources {
            requests = {
              cpu    = var.node_cpu
              memory = var.node_memory
            }
            limits = {
              cpu    = var.node_cpu
              memory = var.node_memory
            }
          }

          # Liveness probe
          liveness_probe {
            http_get {
              path = "/health"
              port = 9944
            }
            initial_delay_seconds = 60
            period_seconds        = 30
            timeout_seconds       = 5
            failure_threshold     = 3
          }

          # Readiness probe
          readiness_probe {
            http_get {
              path = "/health"
              port = 9944
            }
            initial_delay_seconds = 30
            period_seconds        = 10
            timeout_seconds       = 5
            failure_threshold     = 3
          }

          # Startup probe - node takes time to sync
          startup_probe {
            http_get {
              path = "/health"
              port = 9944
            }
            initial_delay_seconds = 10
            period_seconds        = 10
            timeout_seconds       = 5
            failure_threshold     = 30
          }
        }
      }
    }
  }
}

resource "kubernetes_service_v1" "midnight_node" {
  metadata {
    name      = "midnight-node"
    namespace = kubernetes_namespace_v1.midnight_services.metadata[0].name
    labels = {
      app = "midnight-node"
    }
  }

  spec {
    type = "LoadBalancer"

    selector = {
      app = "midnight-node"
    }

    port {
      name        = "rpc"
      port        = 9944
      target_port = 9944
      protocol    = "TCP"
    }
  }
}

# ===========================================
# PROOF SERVER - Deployment + External LB
# ===========================================

resource "kubernetes_deployment_v1" "proof_server" {
  metadata {
    name      = "proof-server"
    namespace = kubernetes_namespace_v1.midnight_services.metadata[0].name
    labels = {
      app = "proof-server"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "proof-server"
      }
    }

    template {
      metadata {
        labels = merge(var.labels, {
          app = "proof-server"
        })
      }

      spec {
        container {
          name  = "proof-server"
          image = var.proof_server_image
          # No command/args needed - proof-server auto-starts and downloads required key material

          port {
            container_port = 6300
            name           = "grpc"
          }

          resources {
            requests = {
              cpu    = var.proof_server_cpu
              memory = var.proof_server_memory
            }
            limits = {
              cpu    = var.proof_server_cpu
              memory = var.proof_server_memory
            }
          }

          # TCP liveness probe (no HTTP endpoint)
          liveness_probe {
            tcp_socket {
              port = 6300
            }
            initial_delay_seconds = 30
            period_seconds        = 30
            timeout_seconds       = 5
            failure_threshold     = 3
          }

          # TCP readiness probe
          readiness_probe {
            tcp_socket {
              port = 6300
            }
            initial_delay_seconds = 15
            period_seconds        = 10
            timeout_seconds       = 5
            failure_threshold     = 3
          }

          # TCP startup probe - proof-server needs time to download ZK key material (~1GB)
          # Total timeout: 10s initial + (60 failures × 10s period) = ~10 minutes
          startup_probe {
            tcp_socket {
              port = 6300
            }
            initial_delay_seconds = 10
            period_seconds        = 10
            timeout_seconds       = 5
            failure_threshold     = 60
          }
        }
      }
    }
  }
}

resource "kubernetes_service_v1" "proof_server" {
  metadata {
    name      = "proof-server"
    namespace = kubernetes_namespace_v1.midnight_services.metadata[0].name
    labels = {
      app = "proof-server"
    }
  }

  spec {
    type = "LoadBalancer"

    selector = {
      app = "proof-server"
    }

    port {
      name        = "grpc"
      port        = 6300
      target_port = 6300
      protocol    = "TCP"
    }
  }
}

# ===========================================
# INDEXER - ConfigMap + StatefulSet + External LB
# Uses SQLite (ephemeral storage OK for dev)
# API endpoint: /api/v3/graphql (v1 redirects to v3)
# ===========================================

resource "kubernetes_config_map_v1" "indexer_config" {
  metadata {
    name      = "indexer-config"
    namespace = kubernetes_namespace_v1.midnight_services.metadata[0].name
    labels = {
      app = "indexer"
    }
  }

  data = {
    "config.yaml" = <<-EOT
      run_migrations: true

      application:
        network_id: "undeployed"
        blocks_buffer: 10
        save_ledger_state_after: 1000
        caught_up_max_distance: 10
        caught_up_leeway: 5
        active_wallets_query_delay: "500ms"
        active_wallets_ttl: "30m"
        transaction_batch_size: 50

      infra:
        # 32-byte hex secret for encryption
        secret: "${var.indexer_secret}"
        
        storage:
          cnn_url: "/data/indexer.sqlite"

        node:
          url: "ws://midnight-node.midnight-services.svc.cluster.local:9944"
          reconnect_max_delay: "10s"
          reconnect_max_attempts: 30
          subscription_recovery_timeout: "30s"

        api:
          address: "0.0.0.0"
          port: 8088
          request_body_limit: "1MiB"
          max_complexity: 200
          max_depth: 15

      telemetry:
        tracing:
          enabled: false
          service_name: "indexer"
          otlp_exporter_endpoint: "http://localhost:4317"
        metrics:
          enabled: false
          address: "0.0.0.0"
          port: 9000
    EOT
  }
}

resource "kubernetes_stateful_set_v1" "indexer" {
  metadata {
    name      = "indexer"
    namespace = kubernetes_namespace_v1.midnight_services.metadata[0].name
    labels = {
      app = "indexer"
    }
  }

  spec {
    service_name = "indexer"
    replicas     = 1

    selector {
      match_labels = {
        app = "indexer"
      }
    }

    template {
      metadata {
        labels = merge(var.labels, {
          app = "indexer"
        })
      }

      spec {
        container {
          name  = "indexer"
          image = var.indexer_image

          # Indexer 3.x uses config file approach (more reliable than env vars)
          # Config is mounted from ConfigMap at /opt/indexer-standalone/config.yaml

          port {
            container_port = 8088
            name           = "http"
          }

          port {
            container_port = 9000
            name           = "metrics"
          }

          resources {
            requests = {
              cpu    = var.indexer_cpu
              memory = var.indexer_memory
            }
            limits = {
              cpu    = var.indexer_cpu
              memory = var.indexer_memory
            }
          }

          # Volume mount for config file
          volume_mount {
            name       = "config"
            mount_path = "/opt/indexer-standalone/config.yaml"
            sub_path   = "config.yaml"
            read_only  = true
          }

          # Volume mount for SQLite data
          volume_mount {
            name       = "data"
            mount_path = "/data"
          }

          # TCP liveness probe
          liveness_probe {
            tcp_socket {
              port = 8088
            }
            initial_delay_seconds = 60
            period_seconds        = 30
            timeout_seconds       = 5
            failure_threshold     = 3
          }

          # TCP readiness probe
          readiness_probe {
            tcp_socket {
              port = 8088
            }
            initial_delay_seconds = 30
            period_seconds        = 10
            timeout_seconds       = 5
            failure_threshold     = 3
          }

          # TCP startup probe - indexer needs time to sync
          startup_probe {
            tcp_socket {
              port = 8088
            }
            initial_delay_seconds = 15
            period_seconds        = 10
            timeout_seconds       = 5
            failure_threshold     = 30
          }
        }

        # Config volume from ConfigMap
        volume {
          name = "config"
          config_map {
            name = kubernetes_config_map_v1.indexer_config.metadata[0].name
          }
        }

        # Ephemeral volume for SQLite
        volume {
          name = "data"
          empty_dir {}
        }
      }
    }
  }
}

resource "kubernetes_service_v1" "indexer" {
  metadata {
    name      = "indexer"
    namespace = kubernetes_namespace_v1.midnight_services.metadata[0].name
    labels = {
      app = "indexer"
    }
  }

  spec {
    type = "LoadBalancer"

    selector = {
      app = "indexer"
    }

    port {
      name        = "http"
      port        = 8088
      target_port = 8088
      protocol    = "TCP"
    }
  }
}
