terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.35.0"
    }
  }

  backend "kubernetes" {
    secret_suffix = "certificates.keycloak"
  }
}

provider "kubernetes" {

}

provider "null" {

}
