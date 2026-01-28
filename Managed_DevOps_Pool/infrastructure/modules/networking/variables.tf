#-------------------------------------
# Global Variables
#------------------------------------
variable "location" {
  description = "Azure region for resources"
  type        = string
}

variable "tags" {
  description = "Tags to apply to the resources"
  type        = map(string)
}

#-------------------------------------
# Resource Group Variables
#------------------------------------
variable "resource_group_name" {
  description = "Name of the resource group where networking resources will be created"
  type        = string
}

#-------------------------------------
# Networking Variables
#------------------------------------
variable "vnet_name" {
  description = "Name of the virtual network"
  type        = string
}

variable "vnet_address_space" {
  description = "Address space for the virtual network"
  type        = list(string)
}

variable "subnets" {
  description = "Map of subnets to create"
  type = map(object({
    name              = string
    address_prefixes  = list(string)
    service_endpoints = optional(list(string), [])
    delegations = optional(list(object({
      name         = string
      service_name = string
      actions      = optional(list(string), [])
    })), [])
  }))
}

variable "nsg_configs" {
  description = "Map of NSG configurations"
  type = map(object({
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
}

variable "managed_devops_pool_subnet_name" {
  description = "Name of the Managed DevOps Pool subnet"
  type        = string
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

variable "nat_gateway_name" {
  description = "Name of the NAT Gateway"
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

variable "nat_gateway_public_ip_name" {
  description = "Name of the NAT Gateway public IP"
  type        = string
}

variable "allocation_method" {
  description = "Allocation method for the public IP (Static or Dynamic)"
  type        = string
}

variable "private_subnet_route_table_name" {
  description = "Name of the route table for the private subnet"
  type        = string
}
