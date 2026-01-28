#-------------------------------------
# Terraform Configuration
#------------------------------------
terraform {
  required_providers {
    azuredevops = {
      source  = "microsoft/azuredevops"
      version = "~> 1.0"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

#-------------------------------------
# Data Sources for Azure client info (current SP/user); Current Azure Subscription metadata; Existing Azure DevOps project; Existing Azure DevOps pipelines (for authorisation)
#------------------------------------
data "azurerm_client_config" "current" {}

data "azurerm_subscription" "current" {}

data "azuredevops_project" "project" { name = var.devops_project_name }

data "azuredevops_build_definition" "pipeline" {
  for_each   = toset(var.pipeline_names)
  name       = each.value
  project_id = data.azuredevops_project.project.id
}

#-------------------------------------
# Service Connection
#------------------------------------
resource "azuredevops_serviceendpoint_azurerm" "service_connection" {
  description                            = var.service_endpoint_description
  project_id                             = data.azuredevops_project.project.id
  service_endpoint_name                  = var.service_endpoint_name
  service_endpoint_authentication_scheme = var.authentication_scheme

  credentials {
    serviceprincipalid  = var.service_principal_id
    serviceprincipalkey = var.service_principal_key
  }

  azurerm_spn_tenantid      = data.azurerm_client_config.current.tenant_id
  azurerm_subscription_id   = var.subscription_id
  azurerm_subscription_name = data.azurerm_subscription.current.display_name
}

#-------------------------------------
# Authorize Service Connection for All Pipelines
#------------------------------------
resource "azuredevops_pipeline_authorization" "authorize_oidc" {
  for_each    = data.azuredevops_build_definition.pipeline
  project_id  = data.azuredevops_project.project.id
  pipeline_id = each.value.id
  resource_id = azuredevops_serviceendpoint_azurerm.service_connection.id
  type        = "endpoint"
}

