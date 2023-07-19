###########################
# Azure Default variables #
###########################

variable "client_id" {
  description = "Azure APP ID for deployment with either AzDo pipelines or GH Actions."
  type = string
  default = "57b0269e-f16e-4020-8845-14cfcc20aea0"
}

variable "client_secret" {
  description = "Azure APP Secret for deployment with either AzDo pipelines or GH Actions."
  type = string  
}

variable "tenant_id" {
  description = "Azure AD Tenant ID"
  type = string
  default = "c453d8b2-90ee-4686-8f75-bb127eadc75f"
}

variable "location" {
  description = "Which datacenter in Azure should these resources be deployed to?"
  type = string
  default = "location"
}

variable "environment" {
  description = "The type of environment, dev, test, staging, prod"
  type = string
  default = "dev"
}

variable "tags" {
  description = "A default set of tags for Azure resources."
  type = map(string)
  default = {
    ProvisionedBy = "Terraform"
    Environment = "Variables are not properly configured."
  }
}

variable "subscription_id" {
  description = "Subscription ID"
  type = string
  default = "b572e8a3-4963-417d-a523-475338a768a7"
}

variable "backstage_image" {
  description = "The Container URL for the backstage image."
  type = string
}

variable "backstage_image_tag" {
  description = "The tag we want to use for our backstage image."
  type = string
  default = "latest"
}

variable "backstage_cpu_cores" {
  description = "The CPU size for the backstage container."
  type = string
  default = "0.5"
}

variable "backstage_memory_in_gb" {
  description = "The amount of memory for the backstage container."
  type = string
  default = "1.5"
}

variable "backstage_port" {
  description = "The network port to use for the backstage container."
  type = number
  default = 80  
}

variable "psql_username" {
  description = "PostgreSQL Username"
  type = string
  default = "psqladmin"
}

variable "app_service_plan_sku" {
  description = "App Service SKU to be used for Linux App"
  type = string
  default = "free"
}

variable "domain" {
  description = "Domain with TLD."
  type = string
  default = "miaka.info"
}

variable "dns_prefix" {
  description = "If there is a domain prefix like dev or staging this should be used."
  type = string
  default = ""
}

variable "backstage_sub_domain" {
  description = "The subdomain you want for the Backstage instance."
  type = string
  default = "backstage"
}

variable "dns_rec_ttl" {
  description = "TTL for DNS records"
  type = number
  default = 300
}

variable "github_token" {
  description = "PAT Token for GitHub connection."
  type = string
}

# variable "auth_github_client_id" {
#   description = "Authentication for Github, Client Id."
#   type = string
# }
# 
# variable "auth_github_client_secret" {
#   description = "Authentication for Github, Client Secret."
#   type = string
# }

variable "github_backstage_appid" {
  description = "Github Integration App ID"
  type = string  
}

variable "github_backstage_clientid" {
  description = "Github Integration ClientID"
  type = string  
}

variable "github_backstage_clientsecret" {
  description = "Github Integration Client Secret"
  type = string
}

variable "github_backstage_webhookurl" {
  description = "Github Integration Webhook URL"
  type = string
}

variable "github_backstage_webhooksecret" {
  description = "Github Integration Webhook Secret"
  type = string
}

variable "github_backstage_privatekey" {
  description = "Github Integration Private Key"
  type = string  
}



