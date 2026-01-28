#-------------------------------------
# Provider Configuration
#------------------------------------
provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
}

provider "azuredevops" {
  org_service_url       = var.devops_org_url
  personal_access_token = var.pat_value
}
