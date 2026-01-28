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
# Custom Data Script Template
#-------------------------------------
locals {
  custom_data = base64encode(templatefile("${path.module}/scripts/install-agent.sh", {
    devops_org_url           = var.devops_org_url
    pat_secret_name          = var.pat_secret_name
    key_vault_name           = var.key_vault_name
    classic_agent_pool_queue = var.classic_agent_pool_queue
    admin_username           = var.admin_username
    storage_account_name     = var.storage_account_name
    location                 = var.location
  }))
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
resource "azuredevops_agent_pool" "classic_agent_pool" {
  name           = var.classic_agent_pool_queue
  auto_provision = false
  auto_update    = true
}

#-------------------------------------
# Azure DevOps Agent Queue
#-------------------------------------
resource "azuredevops_agent_queue" "classic_agent_pool_queue" {
  project_id    = data.azuredevops_project.project.id
  agent_pool_id = azuredevops_agent_pool.classic_agent_pool.id
}

#-------------------------------------
# Azure DevOps Pipeline Authorization - authorisation for all pipelines
#-------------------------------------
resource "azuredevops_pipeline_authorization" "classic_agent_pool_queue" {
  project_id  = data.azuredevops_project.project.id
  resource_id = azuredevops_agent_queue.classic_agent_pool_queue.id
  type        = "queue"
}

#-------------------------------------
# Virtual Machine Scale Set for Azure DevOps Agents
#-------------------------------------
resource "azurerm_linux_virtual_machine_scale_set" "vmss_classic_agent_pool" {
  name                   = var.classic_vmss_name
  resource_group_name    = var.resource_group_name
  location               = var.location
  sku                    = var.classic_vmss_sku
  instances              = var.classic_vmss_instance_count
  admin_username         = var.admin_username
  overprovision          = false
  single_placement_group = false
  custom_data            = local.custom_data

  admin_ssh_key {
    username   = var.admin_username
    public_key = var.admin_ssh_public_key
  }

  source_image_reference {
    publisher = var.classic_vmss_image_publisher
    offer     = var.classic_vmss_image_offer
    sku       = var.classic_vmss_image_sku
    version   = var.classic_vmss_image_version
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = var.classic_vmss_os_disk_type
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
    type         = "UserAssigned"
    identity_ids = [var.user_assigned_identity_id]
  }

  automatic_os_upgrade_policy {
    enable_automatic_os_upgrade = false
    disable_automatic_rollback  = false
  }

  depends_on = [
    var.private_subnet_id
  ]


  tags = var.tags
}