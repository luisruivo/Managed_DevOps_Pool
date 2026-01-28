#------------------------------------
# Global Variables
#------------------------------------
variable "environment" {
  description = "Environment name (dev, test, prod)"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "tags" {
  description = "Tags to apply"
  type        = map(string)
}

#------------------------------------
# Resource Group Variables
#------------------------------------
variable "resource_group_name" {
  description = "Resource group for Bastion"
  type        = string
}

#------------------------------------
# Networking Variables
#------------------------------------
variable "public_subnet_id" {
  description = "ID of the public subnet"
  type        = string
}

#------------------------------------
# Bastion Jump VM Variables
#------------------------------------
variable "bastion_name" {
  description = "Name of the bastion jump VM"
  type        = string
}

variable "bastion_vm_size" {
  description = "Size of the bastion jump VM"
  type        = string
}

variable "bastion_admin_username" {
  description = "Admin username for the bastion jump VM"
  type        = string
}

variable "admin_ssh_public_key" {
  description = "SSH public key for admin user"
  type        = string
}

variable "bastion_os_disk_caching" {
  description = "Caching type for OS disk"
  type        = string
}

variable "bastion_os_disk_storage_account_type" {
  description = "Storage account type for OS disk"
  type        = string
}

variable "bastion_image_publisher" {
  description = "Publisher of the VM image"
  type        = string
}

variable "bastion_image_offer" {
  description = "Offer of the VM image"
  type        = string
}

variable "bastion_image_sku" {
  description = "SKU of the VM image"
  type        = string
}

variable "bastion_image_version" {
  description = "Version of the VM image"
  type        = string
}

variable "bastion_public_ip_name" {
  description = "Name of the public IP for the bastion jump VM"
  type        = string
}

variable "bastion_network_interface_name" {
  description = "Name of the network interface for the bastion jump VM"
  type        = string
}