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
variable "resource_group_id" {
  description = "The resource ID of the resource group"
  type        = string
}

#-------------------------------------
# Networking Variables
#------------------------------------
variable "managed_devops_pool_subnet_id" {
  description = "Subnet ID for the Managed DevOps Pool"
  type        = string
}

#-------------------------------------
# Identity Variables
#------------------------------------
variable "managed_identity_id" {
  description = "The ID of the managed identity"
  type        = string
}

variable "managed_identity_principal_id" {
  description = "Principal ID of the user-assigned managed identity for the Managed DevOps Pool"
  type        = string
}

#-------------------------------------
# Managed DevOps Pool Variables
#------------------------------------
variable "devcenter_name" {
  description = "Name of the DevCenter resource"
  type        = string
}

variable "devcenter_project_name" {
  description = "Name of the DevCenter Project resource"
  type        = string
}

variable "devcenter_project_display_name" {
  description = "Display name for the DevCenter project"
  type        = string
  default     = null
}

variable "devcenter_project_description" {
  description = "Description for the DevCenter project"
  type        = string
  default     = null
}

variable "devops_org_url" {
  description = "URL of the Azure DevOps organization"
  type        = string
}

variable "devops_project_name" {
  description = "Name of the Azure DevOps project"
  type        = string
}

variable "managed_devops_pool_name" {
  description = "Name of the Managed DevOps Pool"
  type        = string
}

variable "managed_devops_pool_maximum_concurrency" {
  description = "Maximum number of concurrent agents"
  type        = number
}

variable "managed_devops_pool_open_access" {
  description = "Whether the pool allows open access"
  type        = bool
}

variable "managed_devops_pool_parallelism" {
  description = "Parallelism for the pool"
  type        = number
}

variable "managed_devops_pool_prediction_preference" {
  description = "Resource prediction preference"
  type        = string
}

variable "managed_devops_pool_vm_sku" {
  description = "VM SKU for the agent pool"
  type        = string
}

variable "managed_devops_pool_image_name" {
  description = "Well-known image name for agents"
  type        = string
}

variable "managed_devops_pool_logon_type" {
  description = "Agent logon type"
  type        = string
}

variable "managed_devops_pool_os_disk_type" {
  description = "OS disk storage account type"
  type        = string
}