variable "namespace" {
  default     = "keycloak"
  description = "Namespace to be used for deploying Keycloak Cluster and related resources."
}

variable "cluster_issuer_name" {
  default     = "photoatom-self-signed-issuer"
  description = "Name for the Cluster Issuer"
}

variable "keycloak_ca_name" {
  default     = "keycloak-ca-certificate"
  description = "Name for the Certificate Authority for Keycloak Cluster"
}

variable "keycloak_issuer_name" {
  default     = "keycloak-ca-issuer"
  description = "Name for the Issuer for Keycloak Cluster"
}

variable "keycloak_certificate_name" {
  default     = "keycloak-certificate"
  description = "Name for the certificate for Keycloak Cluster"
}

variable "cloudflare_email" {
  description = "Email Address to be used for DNS Challenge"
  type        = string
  sensitive   = true
}

variable "cloudflare_token" {
  description = "Token to be used for DNS Challenge"
  type        = string
  sensitive   = true
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

