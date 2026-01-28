#-------------------------------------
# Key Vault Outputs
#-------------------------------------
output "key_vault_id" {
  description = "The ID of the Key Vault"
  value       = azurerm_key_vault.kv.id
}

output "key_vault_name" {
  description = "The name of the Key Vault"
  value       = azurerm_key_vault.kv.name
}

output "key_vault_uri" {
  description = "The URI of the Key Vault"
  value       = azurerm_key_vault.kv.vault_uri
}

output "key_vault_private_endpoint_id" {
  description = "The ID of the Key Vault private endpoint"
  value       = azurerm_private_endpoint.kv_pe.id
}

output "secret_names" {
  description = "Map of secret keys to their names in Key Vault"
  value       = { for k, v in azurerm_key_vault_secret.secrets : k => v.name }
}

output "secret_ids" {
  description = "Map of secret keys to their IDs in Key Vault"
  value       = { for k, v in azurerm_key_vault_secret.secrets : k => v.id }
}