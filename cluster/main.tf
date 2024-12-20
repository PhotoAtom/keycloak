resource "kubernetes_manifest" "keycloak" {
  manifest = {
    "apiVersion" = "k8s.keycloak.org/v2alpha1"
    "kind"       = "Keycloak"
    "metadata" = {
      "labels" = {
        "app"       = "keycloak"
        "component" = "cluster"
      }
      "name"      = var.cluster_name
      "namespace" = var.namespace
    }
    "spec" = {
      "db" = {
        "url" = "jdbc:postgresql://${var.postgres_cluster_name}-rw.${var.postgres_namespace}.svc/keycloak?ssl=true&sslmode=verify-ca&sslrootcert=/mnt/cert/ca.crt&sslcert=/mnt/cert/tls.crt&sslkey=/mnt/key/tls.pk8"
        "passwordSecret" = {
          "key"  = "password"
          "name" = var.keycloak_database_credentials_name
        }
        "poolInitialSize" = 1
        "poolMaxSize"     = 3
        "poolMinSize"     = 1
        "usernameSecret" = {
          "key"  = "username"
          "name" = var.keycloak_database_credentials_name
        }
        "vendor" = "postgres"
      }
      "hostname" = {
        "hostname" = "${var.host_name}.${var.photoatom_domain}"
      }
      "http" = {
        "tlsSecret" = "keycloak-tls"
      }
      "ingress" = {
        "enabled" = false
      }
      "instances" = 2
      "resources" = {
        "limits" = {
          "cpu"    = "500m"
          "memory" = "1Gi"
        }
        "requests" = {
          "cpu"    = "500m"
          "memory" = "1Gi"
        }
      }
      "unsupported" = {
        "podTemplate" = {
          "spec" = {
            "securityContext" = {
              "fsGroup"   = 1000
              "runAsUser" = 1000
            }
            "containers" = [
              {
                "volumeMounts" = [
                  {
                    "name"      = "keycloak-postgres-certificates"
                    "mountPath" = "/mnt/cert"
                  },
                  {
                    "name"      = "keycloak-postgres-keys"
                    "mountPath" = "/mnt/key"
                  }
                ]
              }
            ]
            "volumes" = [
              {
                "name" = "keycloak-postgres-certificates"
                "secret" = {
                  "secretName" = "keycloak-postgresql-ssl-certificates"
                }
              },
              {
                "name" = "keycloak-postgres-keys"
                "secret" = {
                  "secretName" = "keycloak-postgresql-ssl-key"
                }
              }
            ]
          }
        }
      }
    }
  }
}

resource "kubernetes_ingress_v1" "keycloak_ingress" {
  metadata {
    name      = "keycloak-ingress"
    namespace = var.namespace
    labels = {
      app       = "keycloak"
      component = "ingress"
    }
    annotations = {
      "nginx.ingress.kubernetes.io/proxy-ssl-verify" : "off"
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
