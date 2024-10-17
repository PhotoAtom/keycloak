data "kubernetes_secret" "keycloak_database_credentials" {
  metadata {
    name      = var.keycloak_database_credentials_name
    namespace = var.postgres_namespace
  }
}

resource "kubernetes_secret" "keycloak_database_credentials" {
  metadata {
    name      = var.keycloak_database_credentials_name
    namespace = var.namespace

    labels = {
      app       = "keycloak"
      component = "secret"
    }
  }

  data = {
    "username" = data.kubernetes_secret.keycloak_database_credentials.data["username"]
    "password" = data.kubernetes_secret.keycloak_database_credentials.data["password"]
  }

  type = "kubernetes.io/basic-auth"
}

data "kubernetes_secret" "database_certificate_authority" {
  metadata {
    name      = var.database_certificate_authority_name
    namespace = var.postgres_namespace
  }
}

data "kubernetes_secret" "database_ssl_certificates" {
  metadata {
    name      = var.database_ssl_certificates_name
    namespace = var.postgres_namespace
  }
}

resource "kubernetes_secret" "keycloak_database_ssl_certificates" {
  metadata {
    name      = var.keycloak_database_ssl_certificates_name
    namespace = var.namespace

    labels = {
      app       = "keycloak"
      component = "secret"
    }
  }

  data = {
    "ca.crt"  = data.kubernetes_secret.database_certificate_authority.data["ca.crt"]
    "tls.crt" = data.kubernetes_secret.database_ssl_certificates.data["tls.crt"]
  }

  type = "Opaque"
}

resource "kubernetes_secret" "keycloak_database_ssl_key" {
  metadata {
    name      = var.keycloak_database_ssl_key_name
    namespace = var.namespace

    labels = {
      app       = "keycloak"
      component = "secret"
    }
  }

  binary_data = {
    "tls.pk8" = "${filebase64("${path.module}/tls.pk8")}"
  }

  type = "Opaque"
}
