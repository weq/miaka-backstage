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
    github = {
      source  = "integrations/github"
      version = ">= 5.0"
    }
  }
  backend "azurerm" {
    resource_group_name  = "terraform-state"
    storage_account_name = "miakatfstate"
    container_name       = "state"
    key = "prod.backstage.tfstate"
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
  subscription_id = var.subscription_id
  features {}
}

provider "random" {}