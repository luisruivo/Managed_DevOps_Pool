#-------------------------------------
# VMSS Outputs
#-------------------------------------
output "vmss_id" {
  description = "The ID of the VMSS"
  value       = azurerm_linux_virtual_machine_scale_set.vmss.id
}

output "vmss_name" {
  description = "The name of the VMSS"
  value       = azurerm_linux_virtual_machine_scale_set.vmss.name
}

output "vmss_identity" {
  description = "The principal ID of the VMSS managed identity"
  value       = azurerm_linux_virtual_machine_scale_set.vmss.identity[0].principal_id
}