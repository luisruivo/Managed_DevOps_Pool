#------------------------------------
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

#------------------------------------
# Resource Group Variables
#------------------------------------
variable "resource_group_name" {
  description = "Name of the resource group where networking resources will be created"
  type        = string
}

#------------------------------------
# Networking Variables
#------------------------------------
variable "private_subnet_id" {
  description = "ID of the private subnet for the private endpoint"
  type        = string
}

#------------------------------------
# DNS Zone Variables
#------------------------------------
variable "private_dns_zone_vault_id" {
  description = "ID of the private DNS zone for Key Vault"
  type        = string
}

#------------------------------------
# Key Vault Variables
#------------------------------------
variable "key_vault_name" {
  description = "The name of the Key Vault. Must be globally unique across Azure."
  type        = string
}

variable "key_vault_sku_name" {
  description = "SKU name for Key Vault"
  type        = string
}

variable "purge_protection_enabled" {
  description = "Enable purge protection for Key Vault"
  type        = bool
}

variable "enable_rbac_authorization" {
  description = "Enable RBAC authorization for Key Vault"
  type        = bool
}

variable "public_network_access_enabled" {
  description = "Allow public network access to Key Vault"
  type        = bool
}

variable "network_acls_default_action" {
  description = "Default action for network ACLs on Key Vault"
  type        = string
}

variable "network_acls_bypass" {
  description = "Default bypass for network ACLs on Key Vault"
  type        = string
}

variable "private_endpoint_name" {
  description = "Name for the Key Vault private endpoint"
  type        = string
}

variable "private_service_connection_name" {
  description = "Name for the private service connection"
  type        = string
}

variable "is_manual_connection" {
  description = "Whether the private endpoint connection is manual"
  type        = bool
}

variable "subresource_names" {
  description = "List of subresource names for the private endpoint connection"
  type        = list(string)
}

variable "private_dns_zone_group_name" {
  description = "Name for the DNS zone group"
  type        = string
}

variable "key_vault_secrets" {
  description = "Map of secrets to create in Key Vault"
  type = map(object({
    name  = string
    value = string
  }))
}
