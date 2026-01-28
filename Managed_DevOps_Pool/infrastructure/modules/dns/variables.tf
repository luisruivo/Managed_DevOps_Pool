#-------------------------------------
# Global Variables
#------------------------------------
variable "tags" {
  description = "Tags to apply to the DNS resources"
  type        = map(string)
}

#-------------------------------------
# Resource Group Variables
#------------------------------------
variable "resource_group_name" {
  description = "Name of the resource group where DNS resources will be created"
  type        = string
}

#-------------------------------------
# Networking Variables
#------------------------------------
variable "vnet_id" {
  description = "ID of the virtual network to link with the private DNS zones"
  type        = string
}

#-------------------------------------
# DNS Variables
#------------------------------------
variable "private_dns_zone_name" {
  description = "Name of the private DNS zone to create"
  type        = string
}

variable "vnet_link_name" {
  description = "Name of the VNet link"
  type        = string
}
