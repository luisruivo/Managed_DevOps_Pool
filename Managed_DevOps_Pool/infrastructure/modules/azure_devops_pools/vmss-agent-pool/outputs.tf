#-------------------------------------
# VMSS Outputs
#-------------------------------------
output "vmss_id" {
  description = "The ID of the VMSS"
  value       = azurerm_linux_virtual_machine_scale_set.vmss_agent_pool.id
}

output "vmss_name" {
  description = "The name of the VMSS"
  value       = azurerm_linux_virtual_machine_scale_set.vmss_agent_pool.name
}

output "vmss_identity" {
  description = "The principal ID of the VMSS managed identity"
  value       = azurerm_linux_virtual_machine_scale_set.vmss_agent_pool.identity[0].principal_id
}

output "admin_ssh_public_key" {
  description = "The SSH public key for the VMSS admin user"
  value       = [for k in azurerm_linux_virtual_machine_scale_set.vmss_agent_pool.admin_ssh_key : k.public_key][0]
}