#-------------------------------------
# OIDC Role Outputs
#------------------------------------
output "client_id_oidc" {
  description = "Azure AD Application (client) ID"
  value       = azuread_application.devops_oidc.client_id
}

output "object_id_oidc" {
  description = "Azure AD Application (object) ID"
  value       = azuread_application.devops_oidc.object_id
}

output "service_principal_object_id" {
  description = "The object ID of the service principal for OIDC"
  value       = azuread_service_principal.devops_oidc_sp.object_id
}

output "service_connection_id" {
  description = "The ID of the service connection for OIDC"
  value       = var.service_connection_id
}
