variable "namespace" {
  default     = "keycloak"
  description = "Namespace to be used for deploying Keycloak Cluster and related resources."
}

variable "cluster_issuer_name" {
  default     = "photoatom-issuer"
  description = "Name for the Cluster Issuer"
}

variable "cluster_name" {
  default     = "keycloak-cluster"
  description = "Name for the Keycloak Cluster Name"
}

variable "postgres_cluster_name" {
  default     = "postgresql-cluster"
  description = "Name for the PostgreSQL Cluster Name"
}

variable "keycloak_database_credentials_name" {
  default     = "keycloak-database-credentials"
  description = "Database Credentials Secret Name for Keycloak"
}

variable "postgres_namespace" {
  default     = "postgres"
  description = "Namespace to be used for deploying Postgres Cluster and related resources."
}

variable "host_name" {
  default     = "auth"
  description = "Host name to be used with MinIO Tenant Ingress"
}

variable "photoatom_domain" {
  description = "Domain to be used for Ingress"
  default     = ""
  type        = string
}

variable "keycloak_environment_variables" {
  default = [
    {
      name  = "KC_HTTP_PORT"
      value = "8080"
    },
    {
      name  = "KC_HTTPS_PORT"
      value = "8443"
    },
    {
      name  = "KC_HTTPS_CERTIFICATE_FILE"
      value = "/mnt/certs/tls/tls.crt"
    },
    {
      name  = "KC_HTTPS_CERTIFICATE_KEY_FILE"
      value = "/mnt/certs/tls/tls.key"
    },
    {
      name  = "KC_DB_URL"
      value = "jdbc:postgresql://postgresql-cluster-rw.postgres.svc/keycloak?ssl=true&sslmode=verify-full&sslrootcert=/mnt/certs/database/ca/ca.crt&sslcert=/mnt/certs/database/tls.crt&sslkey=/mnt/certs/database/key.der"
    },
    {
      name  = "KC_DB_POOL_INITIAL_SIZE"
      value = "1"
    },
    {
      name  = "KC_DB_POOL_MIN_SIZE"
      value = "1"
    },
    {
      name  = "KC_DB_POOL_MAX_SIZE"
      value = "3"
    },
    {
      name  = "KC_HEALTH_ENABLED"
      value = "true"
    },
    {
      name  = "KC_CACHE"
      value = "ispn"
    },
    {
      name  = "KC_CACHE_STACK"
      value = "kubernetes"
    },
    {
      name  = "KC_PROXY"
      value = "passthrough"
    },
    {
      name  = "KC_TRUSTSTORE_PATHS"
      value = "/var/run/secrets/kubernetes.io/serviceaccount/ca.crt"
    }
  ]

  description = "Environment variables for Keycloak Configuration"
}

variable "keycloak_ports" {
  default = [

    {
      name          = "https"
      containerPort = "8443"
      protocol      = "TCP"
    },
    {
      name          = "http"
      containerPort = "8080"
      protocol      = "TCP"
    },
    {
      name          = "management"
      containerPort = "9000"
      protocol      = "TCP"
    },
    {
      name          = "discovery"
      containerPort = "7800"
      protocol      = "TCP"
    },
  ]

  description = "Keycloak Ports Configuration"
}

variable "keycloak_volumes" {
  default = [

    {
      name       = "keycloak-tls"
      secretName = "keycloak-tls"
    },

    {
      name       = "keycloak-pg-tls"
      secretName = "keycloak-pg-tls"
    },

    {
      name       = "postgres-server-ca-tls"
      secretName = "postgres-server-ca-tls"
    }

  ]

  description = "Mounting secrets as volumes on Keycloak pods"
}

variable "keycloak_volume_mounts" {
  default = [

    {
      name      = "keycloak-tls"
      mountPath = "/mnt/certs/tls"
    },

    {
      name      = "keycloak-pg-tls"
      mountPath = "/mnt/certs/database"
    },

    {
      name      = "postgres-server-ca-tls"
      mountPath = "/mnt/certs/database/ca"
    },

    {
      name      = "photoatom-realm-configuration"
      mountPath = "/opt/keycloak/data/import"
    }
  ]

  description = "Mounting secrets as volumes on Keycloak pods"
}
