#-------------------------------------
# Global Variables
#------------------------------------
variable "subscription_id" {
  description = "Azure subscription ID"
  type        = string
}

variable "devops_project_name" {
  description = "Name of the Azure DevOps project"
  type        = string
}

variable "pipeline_names" {
  description = "List of Azure DevOps pipeline names to authorize"
  type        = list(string)
}

#-------------------------------------
# Service Connection Variables
#------------------------------------
variable "service_endpoint_description" {
  description = "Description for the service endpoint"
  type        = string
}

variable "service_endpoint_name" {
  description = "Name of the service endpoint"
  type        = string
}

variable "authentication_scheme" {
  description = "Authentication scheme (WorkloadIdentityFederation or ServicePrincipal)"
  type        = string
}

variable "service_principal_id" {
  description = "Service Principal ID (Client ID)"
  type        = string
}

variable "service_principal_key" {
  description = "Service Principal Key (Client Secret) - only required for ServicePrincipal auth"
  type        = string
  sensitive   = true
}
