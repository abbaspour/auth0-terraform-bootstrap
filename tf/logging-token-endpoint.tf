resource "null_resource" "build_logger_worker_js" {
  # Trigger a rebuild if the TS file changes
  triggers = {
    source_code_hash = filemd5("${path.module}/../workers/logging-token-endpoint/src/index.ts")
  }

  provisioner "local-exec" {
    command = "cd ${path.module}/../workers/logging-token-endpoint && make"
  }
}

resource "cloudflare_workers_script" "logging_token_endpoint_worker_script" {
  account_id  = var.cloudflare_account_id
  script_name = "logging-token-endpoint"

  content_file       = "${path.module}/../workers/logging-token-endpoint/dist/index.js"
  content_sha256     = filesha256("${path.module}/../workers/logging-token-endpoint/dist/index.js")
  main_module        = "index.js"
  compatibility_date = "2025-12-01"

  bindings = [
    {
      name = "ENDPOINT"
      type = "plain_text"
      text = "https://stg-id.singpass.gov.sg/token"
    }
  ]

  depends_on = [null_resource.build_logger_worker_js]
}

## oidc proxy
resource "auth0_connection" "logging-oidc" {
  name     = "logging-oidc"
  strategy = "oidc"

  options {
    client_id              = "xxx"
    scopes                 = ["openid", "profile"]
    issuer                 = "https://stg-id.singpass.gov.sg"
    authorization_endpoint = "https://stg-id.singpass.gov.sg/auth"
    jwks_uri               = "https://stg-id.singpass.gov.sg/.well-known/keys"
    token_endpoint         = "https://${cloudflare_workers_script.logging_token_endpoint_worker_script.script_name}.abbaspour.workers.dev"
    type                   = "back_channel"
    #discovery_url              = "https://stg-id.singpass.gov.sg/.well-known/openid-configuration"
    token_endpoint_auth_method      = "private_key_jwt"
    #token_endpoint_auth_signing_alg = "ES256"
    connection_settings {
      pkce = "auto"
    }
  }
}

/*
resource "auth0_connection_keys" "logging-oidc-keys" {
  connection_id = auth0_connection.logging-oidc.id

  triggers = {
    version = "1"
    date    = "2025-12-01T00:00:00Z"
  }
}
*/