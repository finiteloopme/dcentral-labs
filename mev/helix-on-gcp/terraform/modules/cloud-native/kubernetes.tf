# Deploy Helix App to the cluster created in main.tf

resource "kubernetes_config_map" "helix_config" {
  metadata {
    name = "helix-config"
  }

  data = {
    "config.toml" = templatefile("${path.module}/config.tpl", {
      db_url    = "postgres://helix:benchmark_password@${google_sql_database_instance.postgres.private_ip_address}:5432/helix_db"
      redis_url = "redis://${google_redis_instance.cache.host}:${google_redis_instance.cache.port}"
    })
  }
  depends_on = [google_container_node_pool.c2_nodes]
}

resource "kubernetes_deployment" "helix" {
  metadata {
    name = "helix-relay"
    labels = { app = "helix" }
  }

  spec {
    replicas = 2
    selector {
      match_labels = { app = "helix" }
    }
    template {
      metadata {
        labels = { app = "helix" }
      }
      spec {
        host_network = true # Bypasses K8s overlay for raw network speed
        dns_policy   = "ClusterFirstWithHostNet"
        
        node_selector = {
          "cloud.google.com/gke-nodepool" = "helix-c2-pool"
        }

        container {
          image = var.image_tag
          name  = "helix"
          command = ["/app/helix"] # Verify binary path in Dockerfile
          args    = ["--config", "/etc/helix/config.toml"]
          
          resources {
            limits = {
              cpu    = "6" # Integer required for static policy
              memory = "24Gi"
            }
            requests = {
              cpu    = "6"
              memory = "24Gi"
            }
          }
          
          volume_mount {
            name       = "config"
            mount_path = "/etc/helix"
          }
          
          port {
            container_port = 18550
            name           = "http"
          }
          port {
            container_port = 9090 # Prometheus Metrics Port
            name           = "metrics"
          }
        }
        volume {
          name = "config"
          config_map {
            name = "helix-config"
          }
        }
      }
    }
  }
}

# GMP: Scrape metrics automatically
resource "kubernetes_manifest" "pod_monitoring" {
  manifest = {
    apiVersion = "monitoring.googleapis.com/v1"
    kind       = "PodMonitoring"
    metadata = {
      name = "helix-monitoring"
    }
    spec = {
      selector = {
        matchLabels = {
          app = "helix"
        }
      }
      endpoints = [
        {
          port = "metrics"
          path = "/metrics"
          interval = "10s"
        }
      ]
    }
  }
}
