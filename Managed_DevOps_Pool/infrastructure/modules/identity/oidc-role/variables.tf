#-------------------------------------
# Azure DevOps Variables
#------------------------------------
variable "devops_project_name" {
  description = "Name of the Azure DevOps project"
  type        = string
}

#-------------------------------------
# Service Connection Variables
#------------------------------------
variable "service_connection_id" {
  description = "The ID of the Azure DevOps service connection"
  type        = string
  default     = null # Necessary for bootstrap phase
}

variable "service_connection_issuer" {
  description = "The workload identity federation issuer from the service connection"
  type        = string
  default     = null # Necessary for bootstrap phase
}

variable "service_connection_subject" {
  description = "The workload identity federation subject from the service connection"
  type        = string
  default     = null # Necessary for bootstrap phase
}

#-------------------------------------
# OIDC Variables
#------------------------------------
variable "oidc_application_display_name" {
  description = "Display name for the Azure AD OIDC application"
  type        = string
}

variable "federated_credential_display_name" {
  description = "Display name for the federated identity credential"
  type        = string
}

variable "audience" {
  description = "The audience for the federated credential."
  type        = list(string)
}
