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
variable "private_dns_zone_blob_id" {
  description = "Resource ID of the Private DNS Zone for Blob Storage"
  type        = string
}

#------------------------------------
# Storage Account Variables
#------------------------------------
variable "storage_account_name" {
  description = "Name of the storage account"
  type        = string
}

variable "account_tier" {
  description = "The tier of the storage account"
  type        = string
}

variable "account_replication_type" {
  description = "The replication type of the storage account"
  type        = string
}

variable "min_tls_version" {
  description = "Minimum TLS version for the storage account"
  type        = string
}

variable "public_network_access_enabled" {
  description = "Allow public network access to Storage Account"
  type        = bool
}

variable "network_rules_default_action" {
  description = "Default action for network rules on Storage Account"
  type        = string
}

variable "network_rules_bypass" {
  description = "Default bypass for network rules on Storage Account"
  type        = list(string)
}

variable "blob_versioning_enabled" {
  description = "Enable blob versioning for the storage account"
  type        = bool
}

variable "containers" {
  description = "Map of containers to create in the storage account"
  type = map(object({
    name                  = string
    container_access_type = optional(string, "private")
  }))
  default = {}
}

variable "container_access_type" {
  description = "Access type for the blob containers"
  type        = string
}

variable "enable_private_endpoint" {
  description = "Whether to create a private endpoint for the storage account"
  type        = bool
}

variable "private_endpoint_name" {
  description = "Name of the storage account private endpoint"
  type        = string
}

variable "private_service_connection_name" {
  description = "Name of the storage account private service connection"
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

variable "blob_dns_zone_group_name" {
  description = "Name of the private DNS zone group for the storage account private endpoint"
  type        = string
}
