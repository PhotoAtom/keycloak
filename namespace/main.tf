// Namespace for Keycloak Cluster
resource "kubernetes_namespace" "keycloak" {
  metadata {
    name = var.namespace
    labels = {
      app       = "keycloak"
      component = "namespace"
    }
  }
}
