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
# Managed Identity Variables
#-------------------------------------
variable "user_assigned_identity_id" {
  description = "ID of the user-assigned managed identity"
  type        = string
}

#-------------------------------------
# VMSS Variables
#-------------------------------------
variable "classic_vmss_name" {
  description = "Name of the vmss agent pool"
  type        = string
}

variable "classic_vmss_sku" {
  description = "VM SKU for the scale set"
  type        = string
}

variable "classic_vmss_instance_count " {
  description = "Number of VMSS instances to start with"
  type        = number
}

variable "admin_username" {
  description = "Admin username for VMs"
  type        = string
  default     = "adminuser"
}

variable "admin_ssh_public_key" {
  description = "SSH public key for admin user"
  type        = string
}

variable "classic_vmss_image_publisher" {
  description = "Image publisher"
  type        = string
}

variable "classic_vmss_image_offer" {
  description = "Image offer"
  type        = string
}

variable "classic_vmss_image_sku" {
  description = "Image SKU"
  type        = string
}

variable "classic_vmss_image_version" {
  description = "Image version"
  type        = string
}

variable "classic_vmss_os_disk_type" {
  description = "OS disk type for the VMSS"
  type        = string
}

# variable "max_instance_count" {
#   description = "Maximum number of VM instances in the scale set"
#   type        = number
#   default     = 5
# }

#-------------------------------------
# locals Variables
#-------------------------------------
variable "classic_agent_pool_queue" {
  description = "Azure DevOps agent pool name"
  type        = string
}

variable "devops_org_url" {
  description = "Azure DevOps organization URL"
  type        = string
}

variable "pat_secret_name" {
  description = "Key Vault secret name for the DevOps PAT"
  type        = string
}

variable "key_vault_name" {
  description = "Key Vault name"
  type        = string
}

variable "storage_account_name" {
  description = "Storage Account name"
  type        = string
}