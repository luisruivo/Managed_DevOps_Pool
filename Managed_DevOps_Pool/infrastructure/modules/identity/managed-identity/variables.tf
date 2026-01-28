#-------------------------------------
# Global Variables
#------------------------------------
variable "location" {
  description = "The Azure region where the managed identity will be created"
  type        = string
}

variable "tags" {
  description = "Tags to apply to the resources"
  type        = map(string)
  default     = {}
}

#-------------------------------------
# Resource Group Variables
#------------------------------------
variable "resource_group_name" {
  description = "The name of the resource group where the managed identity will be created"
  type        = string
}

#-------------------------------------
# Managed Identity Variables
#------------------------------------
variable "managed_identity_name" {
  description = "The full name for the managed identity"
  type        = string
}

variable "role_assignments" {
  description = "List of role assignments to create for the managed identity"
  type = list(object({
    scope                = string
    role_definition_name = string
  }))
  default = []
}