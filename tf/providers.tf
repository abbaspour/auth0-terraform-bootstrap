terraform {
  required_providers {
    auth0 = {
      source  = "auth0/auth0"
      version = "~> 1.36"
    }
    cloudflare = {
      source = "cloudflare/cloudflare"
      version = "~> 5.13"
    }
    null = {
      source  = "hashicorp/null"
      version = ">= 3.2"
    }
  }
}

provider "auth0" {
  domain        = var.auth0_domain
  client_id     = var.auth0_tf_client_id
  client_secret = var.auth0_tf_client_secret
}

provider "cloudflare" {
  email   = var.cloudflare_email
  api_key = var.cloudflare_api_key
}
