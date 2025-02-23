resource "kubernetes_secret" "keycloak_database_credentials" {
  metadata {
    name      = var.keycloak_database_credentials_name
    namespace = var.namespace

    labels = {
      app       = "keycloak"
      component = "secret"
    }

    annotations = {
      "replicator.v1.mittwald.de/replicate-from" = "${var.postgres_namespace}/${var.keycloak_database_credentials_name}"
    }
  }

  data = {
    "username" = ""
    "password" = ""
  }

  lifecycle {
    ignore_changes = [annotations, data]
  }

  type = "kubernetes.io/basic-auth"
}

resource "kubernetes_secret" "keycloak_database_certificates" {
  metadata {
    name      = var.keycloak_database_ssl_certificates_name
    namespace = var.namespace

    labels = {
      app       = "keycloak"
      component = "secret"
    }

    annotations = {
      "replicator.v1.mittwald.de/replicate-from" = "${var.postgres_namespace}/${var.keycloak_database_ssl_certificates_name}"
    }
  }

  data = {
    "ca.crt"  = ""
    "tls.crt" = ""
    "tls.key" = ""
    "key.der" = ""
  }

  lifecycle {
    ignore_changes = [annotations, data]
  }

  type = "kubernetes.io/tls"
}


resource "kubernetes_secret" "database_ca_certificates" {
  metadata {
    name      = var.database_certificate_authority_name
    namespace = var.namespace

    labels = {
      app       = "keycloak"
      component = "secret"
    }

    annotations = {
      "replicator.v1.mittwald.de/replicate-from" = "${var.postgres_namespace}/${var.database_certificate_authority_name}"
    }
  }

  data = {
    "ca.crt"  = ""
    "tls.crt" = ""
    "tls.key" = ""
  }

  lifecycle {
    ignore_changes = [annotations, data]
  }

  type = "kubernetes.io/tls"
}

// Keycloak Credentials
resource "random_password" "keycloak_password" {
  length           = 16
  lower            = true
  numeric          = true
  special          = true
  override_special = "-_*/"
  min_special      = 2
}

resource "kubernetes_secret" "keycloak_credentials" {
  metadata {
    name      = "keycloak-credentials"
    namespace = var.namespace
    labels = {
      app       = "keycloak"
      component = "secret"
    }
  }

  data = {
    KC_BOOTSTRAP_ADMIN_USERNAME = "keycloak.admin"
    KC_BOOTSTRAP_ADMIN_PASSWORD = random_password.keycloak_password.result
  }

  type = "Opaque"
}

// PhotoAtom Realm Secrets
resource "random_password" "tester_client_secret" {
  length           = 16
  lower            = true
  numeric          = true
  special          = true
  override_special = "-_*"
  min_special      = 2
}

resource "random_password" "frontend_client_secret" {
  length           = 16
  lower            = true
  numeric          = true
  special          = true
  override_special = "-_*"
  min_special      = 2
}

resource "kubernetes_secret" "photoatom_client_secrets" {
  metadata {
    name      = "photoatom-client-secrets"
    namespace = var.namespace
    labels = {
      app       = "keycloak"
      component = "secret"
    }
  }

  data = {
    "PHOTOATOM_FRONTEND_CLIENT_SECRET" = base64encode(random_password.frontend_client_secret.result)
    "PHOTOATOM_TESTER_CLIENT_SECRET"   = base64encode(random_password.tester_client_secret.result)
  }

  type = "Opaque"
}

