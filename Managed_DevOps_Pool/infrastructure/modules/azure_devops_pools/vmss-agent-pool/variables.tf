#-------------------------------------
# Global Variables
#-------------------------------------
variable "location" {
  description = "Azure region"
  type        = string
}

variable "tags" {
  description = "Tags to apply"
  type        = map(string)
}

#-------------------------------------
# Resource Group Variables
#-------------------------------------
variable "resource_group_name" {
  description = "Resource group for VMSS"
  type        = string
}

#-------------------------------------
# Networking Variables
#-------------------------------------
variable "private_subnet_id" {
  description = "ID of the private subnet"
  type        = string
}

#-------------------------------------
# DevOps Agent Pools Variables
#-------------------------------------
variable "devops_project_name" {
  description = "Name of the Azure DevOps project"
  type        = string
}

#-------------------------------------
# VMSS Variables
#-------------------------------------
variable "vmss_agent_pool_name" {
  description = "Name of the vmss agent pool"
  type        = string
}

variable "vmss_name" {
  description = "Name of the VM Scale Set"
  type        = string
}

variable "vmss_sku" {
  description = "VM SKU for the scale set"
  type        = string
}

variable "vmss_instance_count" {
  description = "Number of VMSS instances to start with"
  type        = number
}

variable "admin_username" {
  description = "Admin username for VMs"
  type        = string
}

variable "admin_ssh_public_key" {
  description = "SSH public key for admin user"
  type        = string
}

variable "vmss_image_publisher" {
  description = "Image publisher"
  type        = string
}

variable "vmss_image_offer" {
  description = "Image offer"
  type        = string
}

variable "vmss_image_sku" {
  description = "Image SKU"
  type        = string
}

variable "vmss_image_version" {
  description = "Image version"
  type        = string
}

variable "vmss_os_disk_type" {
  description = "OS disk storage account type for VMSS agents"
  type        = string
}

