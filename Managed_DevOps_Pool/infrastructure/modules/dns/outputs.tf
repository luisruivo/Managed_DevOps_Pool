#-------------------------------------
# Private DNS Zone Outputs
#------------------------------------
output "private_dns_zone_id" {
  description = "ID of the private DNS zone"
  value       = azurerm_private_dns_zone.zone.id
}

output "private_dns_zone_name" {
  description = "Name of the private DNS zone"
  value       = azurerm_private_dns_zone.zone.name
}

#-------------------------------------
# VNet Link Outputs
#------------------------------------
output "vnet_link_id" {
  description = "ID of the VNet link"
  value       = azurerm_private_dns_zone_virtual_network_link.vnet_link.id
}

output "vnet_link_name" {
  description = "Name of the VNet link"
  value       = azurerm_private_dns_zone_virtual_network_link.vnet_link.name
}