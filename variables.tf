## auth0
variable "auth0_domain" {
  type = string
  description = "Auth0 Domain"
}

variable "auth0_tf_client_id" {
  type = string
  description = "Auth0 TF provider client_id"
}

variable "auth0_tf_client_secret" {
  type = string
  description = "Auth0 TF provider client_secret"
  sensitive = true
}

variable "auth0_tenant_name" {
  type = string
  description = "Auth0 tenant friendly name"
  default = "My Awesome Tenant"
}

variable "default_password" {
  type = string
  description = "password for test users"
  sensitive = true
}

