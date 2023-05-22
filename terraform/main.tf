##################################################################################################
### Terraform Init
##################################################################################################


terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.52"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = ">= 2.15.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 1.0.0"
    }
  }
  backend "azurerm" {
    resource_group_name  = "terraform-state"
    storage_account_name = "miakatfstate"
    container_name       = "state"
    # key = "poc.backstage.tfstate"
    # subscription_id      = ""
  }
}


##################################################################################################
### Terraform Providers
##################################################################################################

provider "azuread" {
  tenant_id = var.tenant_id
}

provider "azurerm" {
  features {}
}

provider "random" {}

##################################################################################################
### Data
##################################################################################################

# Import credentials for the current user. When run by azure pipelines,
# this will be the values specified in the ARM_* variables.
# Currently only the tenant_id is used in the app config.
data "azurerm_client_config" "current" {
}

data "azuread_application" "pipeline" {
  #application_id = var.pipeline_user_application_id
  application_id = var.client_id
}

data "azuread_service_principal" "pipeline" {
  application_id = data.azuread_application.pipeline.application_id
}


##################################################################################################
### Resources
##################################################################################################

resource "azuread_application" "backstage_login" {
  display_name = "Backstage Login"
  web {
    redirect_uris = [
      "http://localhost:7007/api/auth/microsoft/handler/frame",
      "http://${var.domain}:7007/api/auth/microsoft/handler/frame"
    ]
  }
}

# resource "azuread_service_principal" "backstage_login" {
#   
# }
# 
resource "random_password" "psql_password" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

# Create/manage resource group for the connectfleet_frontend app.
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
  object_id    = azurerm_container_group.backstage.identity[0].principal_id
  secret_permissions = [
    "Get",
    "List"
  ]
}


resource "azurerm_key_vault_secret" "psql_username" {
  key_vault_id = azurerm_key_vault.backstage.id
  name         = "psql-username"
  value        = var.psql_username
  depends_on   = [azurerm_key_vault_access_policy.pipeline]
}

resource "azurerm_key_vault_secret" "psql_password" {
  key_vault_id = azurerm_key_vault.backstage.id
  name         = "psql-password"
  value        = random_password.psql_password.result
  depends_on   = [azurerm_key_vault_access_policy.pipeline]
}

# 
# 
# resource "azurerm_key_vault_secret" "container_registry_password" {
#   key_vault_id = azurerm_key_vault.backstage.id
#   name         = "container-registry-password"
#   value        = var.container_registry_password
#   depends_on   = [azurerm_key_vault_access_policy.pipeline]
# }

resource "azurerm_container_group" "backstage" {
  name                = "ci-backstage"
  resource_group_name = azurerm_resource_group.backstage.name
  location            = azurerm_resource_group.backstage.location
  ip_address_type     = "None"
  os_type             = "Linux"
  #restart_policy      = var.restart_policy
  container {
    name   = "backstage"
    image  = var.backstage_image
    cpu    = var.backstage_cpu_cores
    memory = var.backstage_memory_in_gb
    ports {
      port     = var.backstage_port
      protocol = "TCP"
    }
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
  identity {
    type = "SystemAssigned"
  }
  storage_mb = 65536
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