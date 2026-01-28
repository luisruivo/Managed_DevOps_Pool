#-------------------------------------
# Managed DevOps Pool Outputs
#-------------------------------------
output "devcenter_id" {
  description = "The ID of the DevCenter resource"
  value       = azapi_resource.devcenter.id
}

output "project_id" {
  description = "The ID of the DevCenter project"
  value       = azapi_resource.project.id
}

output "managed_devops_pool_id" {
  description = "The ID of the Managed DevOps Pool"
  value       = azapi_resource.managed_devops_pool.id
}

output "devops_infrastructure_service_principal_object_id" {
  description = "Object ID of the DevOpsInfrastructure service principal"
  value       = data.azuread_service_principal.devops_infrastructure.object_id
}

output "managed_identity_principal_id" {
  description = "Principal ID of the user-assigned managed identity for the Managed DevOps Pool"
  value       = var.managed_identity_principal_id
}