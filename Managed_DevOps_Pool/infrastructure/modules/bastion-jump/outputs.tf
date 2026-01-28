#------------------------------------
# Bastion Jump VM Outputs
#------------------------------------
output "bastion_jump_vm_id" {
  value       = azurerm_linux_virtual_machine.bastion_jump.id
  description = "ID of the bastion jump VM"
}

output "bastion_jump_public_ip" {
  value       = azurerm_public_ip.bastion_jump.ip_address
  description = "Public IP of the bastion jump VM"
}

output "bastion_jump_private_ip" {
  value       = azurerm_network_interface.bastion_jump.private_ip_address
  description = "Private IP of the bastion jump VM"
}

output "bastion_jump_fqdn" {
  value       = azurerm_public_ip.bastion_jump.fqdn
  description = "FQDN of the bastion jump VM"
}