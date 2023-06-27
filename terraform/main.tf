resource "azuread_application" "backstage_login" {
  display_name = "Backstage Login - ${var.environment}"
  web {
    redirect_uris = [
      "http://${var.domain}/api/auth/microsoft/handler/frame"
    ]
  }
}

resource "azuread_service_principal" "backstage_login_sp" {
  application_id = azuread_application.backstage_login.application_id
}

resource "azuread_service_principal_password" "backstage_login_sp_password" {
  service_principal_id = azuread_service_principal.backstage_login_sp.object_id
  end_date_relative = "87600h"
}

resource "random_pet" "backstage" {
  
}
 
resource "random_password" "psql_password" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "azurerm_resource_group" "backstage" {
  name     = "rg-backstage-${var.environment}"
  location = var.location
}

resource "azurerm_key_vault" "backstage" {
  name                = "kv-backstage-${lower(var.environment)}" # Keyvault has name max length of 24 chars
  location            = azurerm_resource_group.backstage.location
  resource_group_name = azurerm_resource_group.backstage.name
  sku_name            = "standard"
  tenant_id           = var.tenant_id
}

resource "azurerm_key_vault_access_policy" "pipeline" {
  key_vault_id = azurerm_key_vault.backstage.id
  tenant_id    = var.tenant_id
  object_id    = data.azuread_service_principal.pipeline.object_id
  secret_permissions = [
    "Get",
    "List",
    "Set",
    "Delete",
    "Purge"
  ]
}

resource "azurerm_key_vault_access_policy" "backstage" {
  key_vault_id = azurerm_key_vault.backstage.id
  tenant_id    = var.tenant_id
  object_id    = azurerm_linux_web_app.backstage.identity[0].principal_id
  secret_permissions = [
    "Get",
    "List"
  ]
}


resource "azurerm_key_vault_secret" "psql_username" {
  key_vault_id = azurerm_key_vault.backstage.id
  name         = "psql-username"
  value        = var.psql_username
  depends_on   = [ azurerm_key_vault_access_policy.pipeline ]
}

resource "azurerm_key_vault_secret" "psql_password" {
  key_vault_id = azurerm_key_vault.backstage.id
  name         = "psql-password"
  value        = random_password.psql_password.result
  depends_on   = [ azurerm_key_vault_access_policy.pipeline ]
}

resource "azurerm_key_vault_secret" "client_id" {
  key_vault_id = azurerm_key_vault.backstage.id
  name = "client-secret"
  value = azuread_service_principal_password.backstage_login_sp_password.value
  depends_on = [ azurerm_key_vault_access_policy.pipeline ]
}

resource "azurerm_key_vault_secret" "client_secret" {
  key_vault_id = azurerm_key_vault.backstage.id
  name = "client-secret"
  value = azuread_service_principal_password.backstage_login_sp_password.value
  depends_on = [ azurerm_key_vault_access_policy.pipeline ]
}

resource "azurerm_key_vault_secret" "github_token" {
  key_vault_id = azurerm_key_vault.backstage.id
  name = "github-token"
  value = var.github_token
  depends_on = [ azurerm_key_vault_access_policy.pipeline ]
}

resource "azurerm_key_vault_secret" "auth_github_client_id" {s
  key_vault_id = azurerm_key_vault.backstage.id
  name = "auth-github-client-id"
  value = var.auth_github_client_id
  depends_on = [ azurerm_key_vault_access_policy.pipeline ]
}

resource "azurerm_key_vault_secret" "auth_github_client_secret" {
  key_vault_id = azurerm_key_vault.backstage.id
  name = "auth-github-client-secret"
  value = var.auth_github_client_secret
  depends_on = [ azurerm_key_vault_access_policy.pipeline ]
}

resource "azurerm_service_plan" "backstage" {
  name                = "asp-backstage-${var.environment}"
  resource_group_name = azurerm_resource_group.backstage.name
  location            = azurerm_resource_group.backstage.location
  os_type             = "Linux"
  sku_name            = var.app_service_plan_sku
}

resource "azurerm_linux_web_app" "backstage" {
  name                = "app-backstage-${var.environment}-${random_pet.backstage.id}"
  resource_group_name = azurerm_resource_group.backstage.name
  location            = azurerm_resource_group.backstage.location
  service_plan_id = azurerm_service_plan.backstage.id
  https_only = true
  #restart_policy      = var.restart_policy
  site_config {
    application_stack {
      docker_image = var.backstage_image
      docker_image_tag = var.backstage_image_tag
    }
  }
  app_settings = {
    POSTGRES_HOST = azurerm_postgresql_flexible_server.backstage.fqdn
    POSTGRES_PORT = 5432
    POSTGRES_USER = azurerm_key_vault_secret.psql_username.value
    POSTGRES_PASSWORD = azurerm_key_vault_secret.psql_password.value
    POSTGRES_PASSWORD = "@Microsoft.KeyVault(VaultName=${azurerm_key_vault.backstage.name};SecretName=${azurerm_key_vault_secret.psql_password.name})"
    AUTH_MICROSOFT_CLIENT_ID = azuread_application.backstage_login.application_id
    AUTH_MICROSOFT_TENANT_ID = var.tenant_id
    AUTH_MICROSOFT_CLIENT_SECRET = "@Microsoft.KeyVault(VaultName=${azurerm_key_vault.backstage.name};SecretName=${azurerm_key_vault_secret.client_secret.name})"
    PGSSLMODE = "verify-full"
    WEBSITES_PORT = 7007
    GITHUB_TOKEN = "@Microsoft.KeyVault(VaultName=${azurerm_key_vault.backstage.name};SecretName=${azurerm_key_vault_secret.github_token.name})"
    AUTH_GITHUB_CLIENT_ID = "@Microsoft.KeyVault(VaultName=${azurerm_key_vault.backstage.name};SecretName=${azurerm_key_vault_secret.auth_github_client_id.name})"
    AUTH_GITHUB_CLIENT_SECRET = "@Microsoft.KeyVault(VaultName=${azurerm_key_vault.backstage.name};SecretName=${azurerm_key_vault_secret.auth_github_client_secret.name})"
  }
  identity {
    type = "SystemAssigned"
  }
  tags = var.tags
}

resource "azurerm_postgresql_flexible_server" "backstage" {
  name = "psql-backstage"
  resource_group_name = azurerm_resource_group.backstage.name
  location = azurerm_resource_group.backstage.location
  version = "14"
  sku_name = "B_Standard_B1ms"
  administrator_login = azurerm_key_vault_secret.psql_username.value
  administrator_password = azurerm_key_vault_secret.psql_password.value
  zone = 1
  #identity {
  #  type = "SystemAssigned"
  #}
  storage_mb = 32768
}

resource "azurerm_dns_cname_record" "backstage" {
  name                = var.backstage_sub_domain
  zone_name           = data.azurerm_dns_zone.tld.name
  resource_group_name = data.azurerm_dns_zone.tld.resource_group_name
  ttl                 = var.dns_rec_ttl
  record              = azurerm_linux_web_app.backstage.default_hostname

}

resource "azurerm_dns_txt_record" "backstage" {
  name                = "asuid.${var.backstage_sub_domain}"
  zone_name           = data.azurerm_dns_zone.tld.name
  resource_group_name = data.azurerm_dns_zone.tld.resource_group_name
  ttl                 = var.dns_rec_ttl
  record {
    value = azurerm_linux_web_app.backstage.custom_domain_verification_id
  }
}

resource "azurerm_app_service_custom_hostname_binding" "backstage" {
  hostname            = trim(azurerm_dns_cname_record.backstage.fqdn, ".")
  app_service_name    = azurerm_linux_web_app.backstage.name
  resource_group_name = azurerm_resource_group.backstage.name
  depends_on          = [azurerm_dns_txt_record.backstage]
  lifecycle {
    ignore_changes = [ssl_state, thumbprint]
  }
}

resource "azurerm_app_service_managed_certificate" "backstage" {
  custom_hostname_binding_id = azurerm_app_service_custom_hostname_binding.backstage.id
}

resource "azurerm_app_service_certificate_binding" "backstage" {
  hostname_binding_id = azurerm_app_service_custom_hostname_binding.backstage.id
  certificate_id      = azurerm_app_service_managed_certificate.backstage.id
  ssl_state           = "SniEnabled"
}

# resource "azurerm_container_app_environment" "backstage" {
#   name = "cae-backstage"
#   location = azurerm_resource_group.backstage.location
#   resource_group_name = azurerm_resource_group.backstage.name
# }
# 
# resource "azurerm_container_app" "backstage" {
#   name = "ca-REPLACEME"
#   container_app_environment_id = azurerm_container_app_environment.REPLACEME.id
#   resource_group_name = azurerm_resource_group.REPLACEME.name
#   revision_mode = "single"
#   template {
#     container {
#       name = "REPLACEME"
#       image = "srtprodacr.azurecr.io/REPLACEME:latest"
#       cpu = 0.25
#       memory = "0.5Gi"
#     }
#   }
# }