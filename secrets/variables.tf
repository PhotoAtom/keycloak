variable "namespace" {
  default     = "keycloak"
  description = "Namespace to be used for deploying Keycloak Cluster and related resources."
}

variable "postgres_namespace" {
  default     = "postgres"
  description = "Namespace to be used for deploying Postgres Cluster and related resources."
}

variable "keycloak_database_credentials_name" {
  default     = "keycloak-database-credentials"
  description = "Database Credentials Secret Name for Keycloak"
}

variable "database_certificate_authority_name" {
  default     = "postgresql-server-ca-tls"
  description = "PostgreSQL Database Certificate Authority Details"
}

variable "keycloak_database_ssl_certificates_name" {
  default     = "keycloak-pg-tls"
  description = "PostgreSQL Database SSL Certificate Details for Keycloak"
}
