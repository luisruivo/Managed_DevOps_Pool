#-------------------------------------
# Storage Account Outputs
#------------------------------------
output "storage_account_name" {
  description = "The name of the storage account"
  value       = azurerm_storage_account.sa.name
}

output "storage_account_id" {
  description = "The ID of the storage account"
  value       = azurerm_storage_account.sa.id
}

#-------------------------------------
# Blob Container Outputs
#------------------------------------
output "containers" {
  description = "Map of all created containers"
  value = {
    for k, container in azurerm_storage_container.containers : k => {
      name = container.name
      id   = container.id
    }
  }
}

#-------------------------------------
# Private Endpoint Outputs
#------------------------------------
output "storage_account_private_endpoint_id" {
  description = "The ID of the storage account private endpoint"
  value       = length(azurerm_private_endpoint.storage_pe) > 0 ? azurerm_private_endpoint.storage_pe[0].id : null # Returns the private endpoint ID if it exists; otherwise, returns null (handles conditional creation with count).
}

#-------------------------------------
# Blob Endpoint Output
#------------------------------------
output "blob_endpoint" {
  description = "The Blob service endpoint URI for the storage account"
  value       = azurerm_storage_account.sa.primary_blob_endpoint
}