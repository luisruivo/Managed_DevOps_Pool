#-------------------------------------
# Terraform Configuration
#-------------------------------------
terraform {
  required_version = ">= 1.0"

  required_providers {
    azuredevops = {
      source  = "microsoft/azuredevops"
      version = "~> 1.0"
    }
  }
}

#-------------------------------------
# Azure DevOps Project Data
#-------------------------------------
data "azuredevops_project" "project" {
  name = var.devops_project_name
}

#-------------------------------------
# Azure DevOps Agent Pool
#-------------------------------------
resource "azuredevops_agent_pool" "vmss_agent_pool" {
  name           = var.vmss_agent_pool_name
  auto_provision = false
  auto_update    = true
}

#-------------------------------------
# Azure DevOps Agent Queue
#-------------------------------------
resource "azuredevops_agent_queue" "vmss_agent_pool_queue" {
  project_id    = data.azuredevops_project.project.id
  agent_pool_id = azuredevops_agent_pool.vmss_agent_pool.id
}

#-------------------------------------
# Azure DevOps Pipeline Authorization - authorisation for all pipelines
#-------------------------------------
resource "azuredevops_pipeline_authorization" "vmss_agent_pool_queue" {
  project_id  = data.azuredevops_project.project.id
  resource_id = azuredevops_agent_queue.vmss_agent_pool_queue.id
  type        = "queue"
}


#-------------------------------------
# Virtual Machine Scale Set for Azure DevOps Agents
#-------------------------------------
resource "azurerm_linux_virtual_machine_scale_set" "vmss_agent_pool" {
  name                        = var.vmss_name
  resource_group_name         = var.resource_group_name
  location                    = var.location
  sku                         = var.vmss_sku
  instances                   = var.vmss_instance_count
  admin_username              = var.admin_username
  upgrade_mode                = "Manual"
  overprovision               = false
  single_placement_group      = false
  platform_fault_domain_count = 1

  admin_ssh_key {
    username   = var.admin_username
    public_key = var.admin_ssh_public_key
  }

  source_image_reference {
    publisher = var.vmss_image_publisher
    offer     = var.vmss_image_offer
    sku       = var.vmss_image_sku
    version   = var.vmss_image_version
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = var.vmss_os_disk_type
  }

  network_interface {
    name    = "nic"
    primary = true

    ip_configuration {
      name      = "internal"
      primary   = true
      subnet_id = var.private_subnet_id
    }
  }

  identity {
    type = "SystemAssigned"
  }

  lifecycle {
    ignore_changes = [instances]
  }

  depends_on = [
    var.private_subnet_id
  ]

  tags = var.tags
}