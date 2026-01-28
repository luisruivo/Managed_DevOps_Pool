#-------------------------------------
# Global Variables
#------------------------------------
variable "location" {
  description = "The Azure region where the resource group will be created"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, test, prod)"
  type        = string
}

variable "subscription_id" {
  description = "The Azure subscription ID where the resources will be created"
  type        = string
}

variable "devops_org_url" {
  description = "Azure DevOps organization URL"
  type        = string
}

variable "devops_project_name" {
  description = "Name of the Azure DevOps project"
  type        = string
}

variable "pipeline_names" {
  description = "List of Azure DevOps pipeline names to authorize"
  type        = list(string)
}

variable "tags" {
  description = "A mapping of tags to assign to the resource group"
  type        = map(string)
}

#-------------------------------------
# Resource Group Variables
#------------------------------------
variable "resource_group_name" {
  description = "The name of the resource group"
  type        = string
}

variable "resource_group_id" {
  description = "The ID of the resource group"
  type        = string
}

#-------------------------------------
# Storage Account Variables
#------------------------------------
variable "storage_account_name" {
  description = "The name of the storage account"
  type        = string
}

variable "storage_account_id" {
  description = "The ID of the storage account"
  type        = string
}

#-------------------------------------
# Networking Variables
#------------------------------------
variable "vnet_configs" {
  description = "Map of VNet configurations to create"
  type = map(object({
    suffix_name   = string
    location      = string
    address_space = list(string)
    specific_tags = optional(map(string), {})
    subnets = map(object({
      name              = string
      address_prefixes  = list(string)
      service_endpoints = optional(list(string), [])
      delegations = optional(list(object({
        name         = string
        service_name = string
        actions      = optional(list(string), [])
      })), [])
    }))
    nsg_configs = map(object({
      name = string
      rules = list(object({
        name                       = string
        priority                   = number
        direction                  = string
        access                     = string
        protocol                   = string
        source_port_range          = string
        destination_port_range     = string
        source_address_prefix      = string
        destination_address_prefix = string
      }))
    }))
  }))
}

variable "managed_devops_pool_subnet_type" {
  description = "Resource type for the Managed DevOps Pool subnet (used by azapi_resource)"
  type        = string
}

variable "managed_devops_pool_subnet_address_prefixes" {
  description = "Address prefixes for the Managed DevOps Pool subnet"
  type        = list(string)
}

variable "managed_devops_pool_subnet_service_endpoints" {
  description = "List of service endpoints for the Managed DevOps Pool subnet"
  type        = list(string)
}

variable "managed_devops_pool_subnet_delegation_name" {
  description = "Name of the subnet delegation"
  type        = string
}

variable "managed_devops_pool_subnet_delegation_service_name" {
  description = "Service name for the subnet delegation"
  type        = string
}

variable "nat_sku_name" {
  description = "SKU name for the NAT Gateway (e.g., Standard)"
  type        = string
}

variable "idle_timeout_in_minutes" {
  description = "Idle timeout in minutes for the NAT Gateway"
  type        = number
}

variable "zones" {
  description = "Availability zones for the NAT Gateway"
  type        = list(string)
}

variable "allocation_method" {
  description = "Allocation method for the public IP (Static or Dynamic)"
  type        = string
}

#-------------------------------------
# DNS Configuration Variables
#-------------------------------------
variable "dns_configs" {
  description = "Map of DNS configurations to create"
  type = map(object({
    private_dns_zone_name = string
    vnet_link_name        = string
    vnet_key              = string
    specific_tags         = optional(map(string), {})
  }))
}

#-------------------------------------
# Key Vault Variables
#------------------------------------
variable "key_vault_configs" {
  description = "Map of Key Vault configurations to create"
  type = map(object({
    name_prefix                     = string
    private_endpoint_name           = string
    private_service_connection_name = string
    private_dns_zone_group_name     = string
    vnet_key                        = string
    subnet_key                      = string
    dns_key                         = string
    sku_name                        = string
    purge_protection_enabled        = bool
    enable_rbac_authorization       = bool
    public_network_access_enabled   = bool
    network_acls_default_action     = string
    network_acls_bypass             = string
    is_manual_connection            = bool
    subresource_names               = list(string)
    specific_tags                   = optional(map(string), {})
  }))
}

variable "key_vault_secrets" {
  description = "Map of secrets to create in Key Vault"
  type = map(object({
    name  = string
    value = string
  }))
}

#-------------------------------------
# Managed DevOps Pool Variables
#------------------------------------
variable "managed_devops_pool_configs" {
  description = "Map of Managed DevOps Pool configurations to create"
  type = map(object({
    vnet_key              = string
    maximum_concurrency   = number
    open_access           = bool
    parallelism           = number
    prediction_preference = string
    vm_sku                = string
    image_name            = string
    logon_type            = string
    os_disk_type          = string
    specific_tags         = optional(map(string), {})
  }))
}

#-------------------------------------
# VMSS Agent Pool Variables
#------------------------------------
variable "vmss_agent_pool_configs" {
  description = "Map of VMSS Agent Pool configurations to create"
  type = map(object({
    vnet_key             = string
    subnet_key           = string
    vmss_sku             = string
    vmss_instance_count  = number
    admin_username       = string
    vmss_image_publisher = string
    vmss_image_offer     = string
    vmss_image_sku       = string
    vmss_image_version   = string
    vmss_os_disk_type    = string
    specific_tags        = optional(map(string), {})
  }))
}

#-------------------------------------
# Authentication Variables
#------------------------------------
variable "pat_value" {
  description = "Azure DevOps Personal Access Token"
  type        = string
  sensitive   = true
}

variable "admin_ssh_public_key" {
  description = "SSH public key for admin user on VMSS agents"
  type        = string
  sensitive   = true
}

#-------------------------------------
# Classic VMSS Agent Pool Variables
#------------------------------------
# variable "classic_vmss_agent_pool_configs" {
#   description = "Map of VMSS Agent Pool configurations to create"
#   type = map(object({
#     vnet_key             = string
#     subnet_key           = string
#     vmss_sku             = string
#     vmss_instance_count  = number
#     admin_username       = string
#     vmss_image_publisher = string
#     vmss_image_offer     = string
#     vmss_image_sku       = string
#     vmss_image_version   = string
#     vmss_os_disk_type    = string
#     specific_tags        = optional(map(string), {})
#   }))
# }

#-------------------------------------
# OIDC Variables
#------------------------------------
variable "audience" {
  description = "The audience for the federated credential."
  type        = list(string)
}

#-------------------------------------
# Service Connection Variables
#------------------------------------
variable "service_connection_configs" {
  description = "Map of service connection configurations to create"
  type = map(object({
    name_suffix           = string
    description           = string
    authentication_scheme = string
    specific_tags         = optional(map(string), {})
  }))
}

#-------------------------------------
# Bastion Variables
#------------------------------------
# variable "bastion_configs" {
#   description = "Map of bastion configurations to create"
#   type = map(object({
#     name_prefix              = string
#     public_ip_name_prefix    = string
#     nic_name_prefix          = string
#     vnet_key                 = string
#     subnet_key               = string
#     vm_size                  = string
#     admin_username           = string
#     os_disk_caching          = string
#     os_disk_storage_account_type = string
#     image_publisher          = string
#     image_offer              = string
#     image_sku                = string
#     image_version            = string
#     specific_tags            = optional(map(string), {})
#   }))
# }