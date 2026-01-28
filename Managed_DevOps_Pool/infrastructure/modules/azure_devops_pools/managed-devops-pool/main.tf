#-------------------------------------
# Terraform Configuration
#------------------------------------
terraform {
  required_providers {
    azapi = {
      source  = "azure/azapi"
      version = "2.5.0"
    }
  }
}

#-------------------------------------
# Get the DevOpsInfrastructure service principal
#-------------------------------------
data "azuread_service_principal" "devops_infrastructure" {
  display_name = "DevOpsInfrastructure"
}

#-------------------------------------
# Register Microsoft.DevCenter Resource Provider
#-------------------------------------
resource "azurerm_resource_provider_registration" "devcenter" {
  name = "Microsoft.DevCenter"
}

#-------------------------------------
# Register Microsoft.DevOpsInfrastructure Resource Provider
#-------------------------------------
resource "azurerm_resource_provider_registration" "devops_infra" {
  name = "Microsoft.DevOpsInfrastructure"
}

#-------------------------------------
# DevCenter Resource
#-------------------------------------
resource "azapi_resource" "devcenter" {
  name      = var.devcenter_name
  type      = "Microsoft.DevCenter/devcenters@2025-02-01"
  location  = var.location
  parent_id = var.resource_group_id

  body = {
    properties = {
      # Add any required properties here
    }
  }

  tags = var.tags

  depends_on = [azurerm_resource_provider_registration.devcenter]
}

#-------------------------------------
# Wait for DevCenter to be ready
#-------------------------------------
resource "time_sleep" "wait_for_devcenter" {
  depends_on      = [azapi_resource.devcenter]
  create_duration = "30s" # Adjust this if needed
}

#-------------------------------------
# DevCenter Project
#-------------------------------------
resource "azapi_resource" "project" {
  name      = var.devcenter_project_name
  type      = "Microsoft.DevCenter/projects@2025-02-01"
  location  = var.location
  parent_id = var.resource_group_id

  body = {
    properties = {
      displayName = var.devcenter_project_display_name
      description = var.devcenter_project_description
      devCenterId = azapi_resource.devcenter.id
      # Add any required properties here
    }
  }

  lifecycle {
    ignore_changes = [tags]
  }

  tags = var.tags

  depends_on = [time_sleep.wait_for_devcenter]

}

#-------------------------------------
# Wait for Project to be fully ready
#-------------------------------------
resource "time_sleep" "wait_for_project" {
  depends_on      = [azapi_resource.project]
  create_duration = "30s" # Adjust this if needed
}

#-------------------------------------
# Managed DevOps Pool
#-------------------------------------
resource "azapi_resource" "managed_devops_pool" {
  name                      = var.managed_devops_pool_name
  type                      = "Microsoft.DevOpsInfrastructure/pools@2025-01-21"
  location                  = var.location
  parent_id                 = var.resource_group_id
  schema_validation_enabled = false

  identity {
    type         = "UserAssigned"
    identity_ids = [var.managed_identity_id]
  }

  body = {
    properties = {
      devCenterProjectResourceId = azapi_resource.project.id
      maximumConcurrency         = var.managed_devops_pool_maximum_concurrency

      organizationProfile = {
        kind = "AzureDevOps"
        organizations = [
          {
            openAccess  = var.managed_devops_pool_open_access
            parallelism = var.managed_devops_pool_parallelism
            projects    = [var.devops_project_name]
            url         = var.devops_org_url
          }
        ]
        permissionProfile = {
          kind   = "CreatorOnly"
          users  = []
          groups = []
        }
      }

      agentProfile = {
        kind = "Stateless"
        resourcePredictionsProfile = {
          kind                 = "Automatic"
          predictionPreference = var.managed_devops_pool_prediction_preference
        }
      }

      fabricProfile = {
        kind = "Vmss"
        networkProfile = {
          subnetId = var.managed_devops_pool_subnet_id
        }
        sku = {
          name = var.managed_devops_pool_vm_sku
        }
        images = [
          {
            wellKnownImageName = var.managed_devops_pool_image_name
            aliases            = [var.managed_devops_pool_image_name]
          }
        ]
        osProfile = {
          logonType = var.managed_devops_pool_logon_type
        }
        storageProfile = {
          osDiskStorageAccountType = var.managed_devops_pool_os_disk_type
        }
      }
    }
  }

  tags = var.tags

  depends_on = [
    time_sleep.wait_for_project,
    azurerm_resource_provider_registration.devops_infra
  ]
}
