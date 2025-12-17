# Midnight Kubernetes Services Module
#
# Deploys Midnight standalone services to an existing GKE cluster:
# - midnight-node: Blockchain node (StatefulSet with Internal LB)
# - proof-server: Zero-knowledge proof generation (Deployment with Internal LB)
# - indexer: Blockchain indexer using SQLite (StatefulSet with Internal LB)
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
# MIDNIGHT NODE - StatefulSet + Internal LB
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

          # Use CFG_PRESET env var instead of CLI args
          # For dev mode: CFG_PRESET=dev enables local development chain
          env {
            name  = "CFG_PRESET"
            value = local.is_dev_mode ? "dev" : var.chain_environment
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
    annotations = {
      "cloud.google.com/load-balancer-type" = "Internal"
    }
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
# PROOF SERVER - Deployment + Internal LB
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
    annotations = {
      "cloud.google.com/load-balancer-type" = "Internal"
    }
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
# INDEXER - StatefulSet + Internal LB
# Uses SQLite (ephemeral storage OK for dev)
# ===========================================

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

          # Indexer uses APP__* env var naming convention (double underscore = nested config)
          # Only required env vars - others have sensible defaults

          # WebSocket connection to midnight-node
          env {
            name  = "APP__INFRA__NODE__URL"
            value = "ws://midnight-node.midnight-services.svc.cluster.local:9944"
          }

          # Required secret (32-byte hex string) - must be set in .env
          env {
            name  = "APP__INFRA__SECRET"
            value = var.indexer_secret
          }

          port {
            container_port = 8088
            name           = "http"
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
    annotations = {
      "cloud.google.com/load-balancer-type" = "Internal"
    }
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
