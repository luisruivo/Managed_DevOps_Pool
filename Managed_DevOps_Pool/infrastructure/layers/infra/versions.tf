#-------------------------------------
# Terraform Configuration
#------------------------------------
terraform {
  required_version = "1.13.1"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.48.0"
    }
    azuredevops = {
      source  = "microsoft/azuredevops"
      version = "~> 1.0"
    }
    azapi = {
      source  = "azure/azapi"
      version = "2.5.0"
    }
  }
}