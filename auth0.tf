resource "auth0_tenant" "tenant_config" {
  friendly_name = var.auth0_tenant_name
  flags {
    enable_client_connections = false
  }
}

data "auth0_resource_server" "api_v2" {
  identifier = "https://${var.auth0_domain}/api/v2/"
}

data "auth0_connection" "db" {
  name = "Username-Password-Authentication"
}

/*
resource "auth0_connection" "google" {
  name = "google-oauth2"
  strategy = "google-oauth2"

  options {
  }
}

resource "auth0_connection" "facebook" {
  name = "facebook"
  strategy = "facebook"

  options {
  }
}
*/

# simple SPA client
resource "auth0_client" "spa" {
  name            = "SPA"
  description     = "Gallery SPA client"
  app_type        = "spa"
  oidc_conformant = true
  is_first_party  = true

  callbacks = [
    "https://jwt.io"
  ]

  allowed_logout_urls = [
  ]

  jwt_configuration {
    alg = "RS256"
  }
}

# Connection vs Clients
resource "auth0_connection_clients" "users_clients" {
  connection_id = data.auth0_connection.db.id
  enabled_clients = [auth0_client.spa.id, var.auth0_tf_client_id]
  lifecycle {
    ignore_changes = [enabled_clients]
  }
}

## Users
resource "auth0_user" "user_1" {
  depends_on = [auth0_connection_clients.users_clients]
  connection_name = data.auth0_connection.db.name
  email           = "user1@atko.email"
  password        = var.default_password
}

## outputs
output "spa_login_url" {
  value = "https://${var.auth0_domain}/authorize?client_id=${auth0_client.spa.id}&redirect_uri=https%3A%2F%2Fjwt.io&response_type=id_token&nonce=nonce&prompt=login&scope=openid%20profile%20email"
}



