#-------------------------------------
# Service Connection Outputs
#------------------------------------
output "service_connection_id" {
  description = "ID of the Azure DevOps service connection"
  value       = azuredevops_serviceendpoint_azurerm.service_connection.id
}

output "service_connection_name" {
  description = "Name of the Azure DevOps service connection"
  value       = azuredevops_serviceendpoint_azurerm.service_connection.service_endpoint_name
}

output "service_connection_issuer" {
  description = "The workload identity federation issuer URL (only for OIDC)"
  value       = var.authentication_scheme == "WorkloadIdentityFederation" ? azuredevops_serviceendpoint_azurerm.service_connection.workload_identity_federation_issuer : null
}

output "service_connection_subject" {
  description = "The workload identity federation subject (only for OIDC)"
  value       = var.authentication_scheme == "WorkloadIdentityFederation" ? azuredevops_serviceendpoint_azurerm.service_connection.workload_identity_federation_subject : null
}

# output "project_id" {
#   description = "Azure DevOps project ID"
#   value       = data.azuredevops_project.project.id
# }

# output "service_connection_issuer" {
#   description = "The workload identity federation issuer URL"
#   value       = azuredevops_serviceendpoint_azurerm.oidc.workload_identity_federation_issuer
# }

# output "service_connection_subject" {
#   description = "The workload identity federation subject"
#   value       = azuredevops_serviceendpoint_azurerm.oidc.workload_identity_federation_subject
# }