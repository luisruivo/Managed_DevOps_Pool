#------------------------------------
# Global Variables
#------------------------------------
variable "location" {
  description = "Azure region where resources will be created"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, test, prod)"
  type        = string
}

variable "subscription_id" {
  description = "Azure Subscription ID"
  type        = string
}

variable "tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
}

#------------------------------------
# Resource Group Variables
#------------------------------------
variable "resource_groups" {
  description = "Map of resource groups to create"
  type = map(object({
    suffix_name   = string
    location      = string
    specific_tags = optional(map(string), {})
  }))
}


#------------------------------------
# Networking Variables
#------------------------------------
variable "private_subnet_id" {
  description = "ID of the private subnet for the private endpoint"
  type        = string
}

#------------------------------------
# DNS Variables
#------------------------------------
variable "private_dns_zone_blob_id" {
  description = "Resource ID of the Private DNS Zone for blob.core.windows.net"
  type        = string
}

#------------------------------------
# Storage Account Variables
#------------------------------------
variable "storage_accounts" {
  description = "Map of storage accounts to create"
  type = map(object({
    suffix_name        = string
    resource_group_key = string
    containers = map(object({
      name                  = string
      container_access_type = string
    }))
    private_endpoint_name           = string
    private_service_connection_name = string
    specific_tags                   = optional(map(string), {})
  }))
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

variable "container_access_type" {
  description = "Access type for the blob containers"
  type        = string
}

variable "enable_private_endpoint" {
  description = "Whether to create a private endpoint for the storage account"
  type        = bool
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
