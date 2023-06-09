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

data "azurerm_resource_group" "dns" {
  name = "rg-${var.domain}"
}

data "azurerm_dns_zone" "tld" {
  name                = "${var.dns_prefix}${var.domain}"
  resource_group_name = data.azurerm_resource_group.dns.name
}