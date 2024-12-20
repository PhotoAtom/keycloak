// Certificate Authority to be used with Keycloak Cluster
resource "kubernetes_manifest" "keycloak_ca" {
  manifest = {
    "apiVersion" = "cert-manager.io/v1"
    "kind"       = "Certificate"
    "metadata" = {
      "name"      = "${var.keycloak_ca_name}"
      "namespace" = "${var.namespace}"
      "labels" = {
        "app"       = "keycloak"
        "component" = "ca"
      }
    }
    "spec" = {
      "isCA" = true
      "subject" = {
        "organizations"       = ["photoatom"]
        "countries"           = ["India"]
        "organizationalUnits" = ["Keycloak"]
      }
      "commonName" = "keycloak-ca"
      "secretName" = "keycloak-ca-tls"
      "duration"   = "70128h"
      "privateKey" = {
        "algorithm" = "ECDSA"
        "size"      = 256
      }
      "issuerRef" = {
        "name"  = "${var.cluster_issuer_name}"
        "kind"  = "ClusterIssuer"
        "group" = "cert-manager.io"
      }
    }
  }
}

// Issuer for the Keycloak Cluster Namespace
resource "kubernetes_manifest" "keycloak_issuer" {
  manifest = {
    "apiVersion" = "cert-manager.io/v1"
    "kind"       = "Issuer"
    "metadata" = {
      "name"      = "${var.keycloak_issuer_name}"
      "namespace" = "${var.namespace}"
      "labels" = {
        "app"       = "keycloak"
        "component" = "issuer"
      }
    }
    "spec" = {
      "ca" = {
        "secretName" = "keycloak-ca-tls"
      }
    }
  }

  depends_on = [kubernetes_manifest.keycloak_ca]
}

// Certificate for Keycloak Cluster
resource "kubernetes_manifest" "keycloak_certificate" {
  manifest = {
    "apiVersion" = "cert-manager.io/v1"
    "kind"       = "Certificate"
    "metadata" = {
      "name"      = "${var.keycloak_certificate_name}"
      "namespace" = "${var.namespace}"
      "labels" = {
        "app"       = "keycloak"
        "component" = "certificate"
      }
    }
    "spec" = {
      "dnsNames" = [
        "${var.host_name}.${var.photoatom_domain}",
        "localhost",
        "127.0.0.1",
        "*.keycloak.svc.cluster.local",
        "keycloak-cluster-service",
        "keycloak-cluster-service.keycloak.svc.cluster.local",
        "*.keycloak-cluster-service.keycloak.svc.cluster.local",
        "keycloak-cluster-discovery",
        "keycloak-cluster-discovery.keycloak.svc.cluster.local",
        "*.keycloak-cluster-discovery.keycloak.svc.cluster.local",
      ]
      "subject" = {
        "organizations"       = ["photoatom"]
        "countries"           = ["India"]
        "organizationalUnits" = ["Keycloak"]
      }
      "commonName" = "keycloak"
      "secretName" = "keycloak-tls"
      "issuerRef" = {
        "name" = "${var.keycloak_issuer_name}"
      }
    }
  }

  depends_on = [kubernetes_manifest.keycloak_issuer]
}

// Kubernetes Secret for Cloudflare Tokens
resource "kubernetes_secret" "cloudflare_token" {
  metadata {
    name      = "cloudflare-token"
    namespace = var.namespace
    labels = {
      "app"       = "keycloak"
      "component" = "secret"
    }

  }

  data = {
    cloudflare-token = var.cloudflare_token
  }

  type = "Opaque"
}

// Cloudflare Issuer for Keycloak Ingress Service
resource "kubernetes_manifest" "keycloak_public_issuer" {
  manifest = {
    "apiVersion" = "cert-manager.io/v1"
    "kind"       = "Issuer"
    "metadata" = {
      "name"      = "keycloak-public-issuer"
      "namespace" = var.namespace
      "labels" = {
        "app"       = "keycloak"
        "component" = "issuer"
      }
    }
    "spec" = {
      "acme" = {
        "email"  = var.cloudflare_email
        "server" = "https://acme-v02.api.letsencrypt.org/directory"
        "privateKeySecretRef" = {
          "name" = "keycloak-issuer-key"
        }
        "solvers" = [
          {
            "dns01" = {
              "cloudflare" = {
                "email" = var.cloudflare_email
                "apiTokenSecretRef" = {
                  "name" = "cloudflare-token"
                  "key"  = "cloudflare-token"
                }
              }
            }
          }
        ]
      }
    }
  }

  depends_on = [kubernetes_secret.cloudflare_token]
}

// Certificate to be used for Keycloak Ingress
resource "kubernetes_manifest" "keycloak_ingress_certificate" {

  manifest = {
    "apiVersion" = "cert-manager.io/v1"
    "kind"       = "Certificate"
    "metadata" = {
      "name"      = "keycloak-ingress-certificate"
      "namespace" = var.namespace
      "labels" = {
        "app"       = "keycloak"
        "component" = "certificate"
      }
    }
    "spec" = {
      "duration"    = "2160h"
      "renewBefore" = "360h"
      "subject" = {
        "organizations"       = ["photoatom"]
        "countries"           = ["India"]
        "organizationalUnits" = ["keycloak"]
      }
      "privateKey" = {
        "algorithm" = "RSA"
        "encoding"  = "PKCS1"
        "size"      = "2048"
      }
      "dnsNames"   = ["${var.host_name}.${var.photoatom_domain}"]
      "secretName" = "keycloak-ingress-tls"
      "issuerRef" = {
        "name"  = "keycloak-public-issuer"
        "kind"  = "Issuer"
        "group" = "cert-manager.io"
      }
    }
  }

  depends_on = [kubernetes_manifest.keycloak_public_issuer]

}
