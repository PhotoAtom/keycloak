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
      "isCA"       = true
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
        "auth.photoatom.local"
      ]
      "secretName" = "keycloak-tls"
      "issuerRef" = {
        "name" = "${var.keycloak_issuer_name}"
      }
    }
  }

  depends_on = [kubernetes_manifest.keycloak_issuer]
}
