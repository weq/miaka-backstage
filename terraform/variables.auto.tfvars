location = "eastus2"
tags = {
    ProvisionedBy = "Terraform"
    Environment = "production"
    Pipeline = "Github Actions"
    Customer = "Miaka"
}
environment = "prod"
backstage_image = "weqew/backstage-poc"
backstage_image_tag = "latest"
backstage_cpu_cores = "0.5"
backstage_memory_in_gb = "1.5"
backstage_port = 80
domain = "miaka.info"
backstage_sub_domain = "backstage"
app_service_plan_sku = "B1"
dns_prefix = ""