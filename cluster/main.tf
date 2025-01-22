// Keycloak Discovery Service
resource "kubernetes_service" "keycloak_discovery" {
  metadata {
    name      = "keycloak-discovery"
    namespace = var.namespace
  }

  spec {
    selector = {
      app       = "keycloak"
      component = "pod"
    }
    session_affinity = "None"
    port {
      name        = "discovery"
      port        = 7800
      target_port = "discovery"
    }
    type       = "ClusterIP"
    cluster_ip = "None"
  }
}

// Keycloak HTTP(S) and Management Service
resource "kubernetes_service" "keycloak_service" {
  metadata {
    name      = "keycloak-cluster-service"
    namespace = var.namespace
  }

  spec {
    selector = {
      app       = "keycloak"
      component = "pod"
    }
    session_affinity = "None"
    port {
      name        = "http"
      port        = 8080
      target_port = "http"
    }
    port {
      name        = "https"
      port        = 8443
      target_port = "https"
    }
    port {
      name        = "management"
      port        = 9000
      target_port = "management"
    }
    type = "ClusterIP"
  }
}

// Keycloak Stateful Set Cluster
resource "kubernetes_stateful_set" "keycloak_cluster" {
  metadata {
    name      = "keycloak-cluster"
    namespace = var.namespace
    labels = {
      app       = "keycloak"
      component = "statefulset"
    }
  }
  spec {
    replicas     = 1
    service_name = ""

    // Stateful Set Pod Selector
    selector {
      match_labels = {

        app       = "keycloak"
        component = "pod"

      }
    }

    // Pod Template
    template {

      // Pod Metadata
      metadata {
        labels = {
          app       = "keycloak"
          component = "pod"
        }
      }

      // Pod Spec
      spec {

        // Container Details
        container {
          name  = "keycloak"
          image = "quay.io/keycloak/keycloak:26.0.7"
          args  = ["-Djgroups.dns.query=keycloak-discovery.keycloak", "--verbose", "start", "--import-realm"]

          // Environment Variables
          env {
            name  = "KC_HOSTNAME"
            value = "${var.host_name}.${var.photoatom_domain}"
          }

          dynamic "env" {
            for_each = var.keycloak_environment_variables
            content {
              name  = env.value["name"]
              value = env.value["value"]
            }
          }

          env_from {
            secret_ref {
              name = "keycloak-credentials"
            }
          }

          env_from {
            secret_ref {
              name = "keycloak-client-secrets"
            }
          }

          env {
            name  = "KC_DB"
            value = "postgres"
          }

          env {
            name = "KC_DB_USERNAME"
            value_from {
              secret_key_ref {
                name = "keycloak-database-credentials"
                key  = "username"
              }
            }
          }

          env {
            name = "KC_DB_PASSWORD"
            value_from {
              secret_key_ref {
                name = "keycloak-database-credentials"
                key  = "password"
              }
            }
          }

          // Port Mappings
          dynamic "port" {
            for_each = var.keycloak_ports
            content {
              name           = port.value["name"]
              container_port = port.value["containerPort"]
              protocol       = port.value["protocol"]
            }
          }

          // Startup, Liveness and Readiness Probes
          startup_probe {
            failure_threshold = 3
            http_get {
              path   = "/health/started"
              port   = "management"
              scheme = "HTTPS"
            }
            period_seconds        = 10
            success_threshold     = 1
            timeout_seconds       = 10
            initial_delay_seconds = 60
          }

          readiness_probe {
            failure_threshold = 3
            http_get {
              path   = "/health/ready"
              port   = "management"
              scheme = "HTTPS"
            }
            period_seconds        = 10
            success_threshold     = 1
            timeout_seconds       = 10
            initial_delay_seconds = 60
          }

          liveness_probe {
            failure_threshold = 3
            http_get {
              path   = "/health/live"
              port   = "management"
              scheme = "HTTPS"
            }
            period_seconds        = 10
            success_threshold     = 1
            timeout_seconds       = 10
            initial_delay_seconds = 60
          }

          // Resource limitations
          resources {
            requests = {
              "cpu"    = "500m"
              "memory" = "1Gi"
            }

            limits = {
              "cpu"    = "500m"
              "memory" = "1Gi"
            }
          }

          // Volume mounts
          dynamic "volume_mount" {
            for_each = var.keycloak_volume_mounts
            content {
              name       = volume_mount.value["name"]
              mount_path = volume_mount.value["mountPath"]
            }
          }

        }

        // Volumes
        dynamic "volume" {
          for_each = var.keycloak_volumes
          content {
            name = volume.value["name"]
            secret {
              secret_name = volume.value["secretName"]
            }
          }
        }

        volume {
          name = "photoatom-realm-configuration"
          config_map {
            name = "photoatom-realm-configuration"
          }
        }

        security_context {
          fs_group    = 1000
          run_as_user = 1000
        }

      }
    }

    update_strategy {
      rolling_update {
        partition = 0
      }
      type = "RollingUpdate"
    }
  }

  depends_on = [kubernetes_service.keycloak_service, kubernetes_service.keycloak_discovery]
}

# resource "kubernetes_manifest" "keycloak" {
#   manifest = {
#     "apiVersion" = "k8s.keycloak.org/v2alpha1"
#     "kind"       = "Keycloak"
#     "metadata" = {
#       "labels" = {
#         "app"       = "keycloak"
#         "component" = "cluster"
#       }
#       "name"      = var.cluster_name
#       "namespace" = var.namespace
#     }
#     "spec" = {
#       "db" = {
#         "url" = "jdbc:postgresql://${var.postgres_cluster_name}-rw.${var.postgres_namespace}.svc/keycloak?ssl=true&sslmode=verify-ca&sslrootcert=/mnt/cert/ca.crt&sslcert=/mnt/cert/tls.crt&sslkey=/mnt/key/tls.pk8"
#         "passwordSecret" = {
#           "key"  = "password"
#           "name" = var.keycloak_database_credentials_name
#         }
#         "poolInitialSize" = 1
#         "poolMaxSize"     = 3
#         "poolMinSize"     = 1
#         "usernameSecret" = {
#           "key"  = "username"
#           "name" = var.keycloak_database_credentials_name
#         }
#         "vendor" = "postgres"
#       }
#       "hostname" = {
#         "hostname" = "${var.host_name}.${var.photoatom_domain}"
#       }
#       "http" = {
#         "tlsSecret" = "keycloak-tls"
#       }
#       "ingress" = {
#         "enabled" = false
#       }
#       "instances" = 1
#       "resources" = {
#         "limits" = {
#           "cpu"    = "500m"
#           "memory" = "1Gi"
#         }
#         "requests" = {
#           "cpu"    = "500m"
#           "memory" = "1Gi"
#         }
#       }
#       "unsupported" = {
#         "podTemplate" = {
#           "spec" = {
#             "securityContext" = {
#               "fsGroup"   = 1000
#               "runAsUser" = 1000
#             }
#             "containers" = [
#               {
#                 "args" : ["--verbose", "start", "--import-realm"]
#                 "volumeMounts" = [
#                   {
#                     "name"      = "keycloak-postgres-certificates"
#                     "mountPath" = "/mnt/cert"
#                   },
#                   {
#                     "name"      = "keycloak-postgres-keys"
#                     "mountPath" = "/mnt/key"
#                   },
#                   {
#                     "name"      = "photoatom-realm-configuration"
#                     "mountPath" = "/opt/keycloak/data/import"
#                   }
#                 ]
#                 "envFrom" = [
#                   {
#                     "secretRef" = {
#                       "name" : "photoatom-client-secrets"
#                     }
#                   }
#                 ]
#               }
#             ]
#             "volumes" = [
#               {
#                 "name" = "keycloak-postgres-certificates"
#                 "secret" = {
#                   "secretName" = "keycloak-postgresql-ssl-certificates"
#                 }
#               },
#               {
#                 "name" = "keycloak-postgres-keys"
#                 "secret" = {
#                   "secretName" = "keycloak-postgresql-ssl-key"
#                 }
#               },
#               {
#                 "name" = "photoatom-realm-configuration"
#                 "configMap" = {
#                   "name" = "photoatom-realm-configuration"
#                 }
#               }
#             ]
#           }
#         }
#       }
#     }
#   }
# }

resource "kubernetes_ingress_v1" "keycloak_ingress" {
  metadata {
    name      = "keycloak-ingress"
    namespace = var.namespace
    labels = {
      app       = "keycloak"
      component = "ingress"
    }
    annotations = {
      "nginx.ingress.kubernetes.io/proxy-ssl-verify" : "on"
      "nginx.ingress.kubernetes.io/proxy-ssl-secret" : "keycloak/keycloak-tls"
      "nginx.ingress.kubernetes.io/proxy-ssl-name" : "keycloak-cluster-service.keycloak.svc.cluster.local"
      "nginx.ingress.kubernetes.io/backend-protocol" : "HTTPS"
      "nginx.ingress.kubernetes.io/rewrite-target" : "/"
      "nginx.ingress.kubernetes.io/proxy-body-size" : 0
    }
  }

  spec {
    ingress_class_name = "nginx"
    tls {
      hosts       = ["${var.host_name}.${var.photoatom_domain}"]
      secret_name = "keycloak-ingress-tls"
    }
    rule {
      host = "${var.host_name}.${var.photoatom_domain}"
      http {
        path {
          path = "/"
          backend {
            service {
              name = "keycloak-cluster-service"
              port {
                number = 8443
              }
            }
          }
        }
      }
    }
  }

  depends_on = [kubernetes_manifest.keycloak]
}
