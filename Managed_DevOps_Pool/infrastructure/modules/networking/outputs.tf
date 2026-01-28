#-------------------------------------
# Virtual Network Outputs
#------------------------------------
output "vnet_id" {
  description = "ID of the virtual network"
  value       = azurerm_virtual_network.vnet.id
}

output "vnet_name" {
  description = "Name of the virtual network"
  value       = azurerm_virtual_network.vnet.name
}

output "vnet_address_space" {
  description = "Address space of the virtual network"
  value       = azurerm_virtual_network.vnet.address_space
}

#-------------------------------------
# Subnets Outputs
#------------------------------------
output "subnet_ids" {
  description = "Map of subnet names to their IDs"
  value       = { for k, v in azurerm_subnet.subnets : k => v.id }
}

output "subnet_names" {
  description = "Map of subnet keys to their names"
  value       = { for k, v in azurerm_subnet.subnets : k => v.name }
}

output "subnet_address_prefixes" {
  description = "Map of subnet keys to their address prefixes"
  value       = { for k, v in azurerm_subnet.subnets : k => v.address_prefixes }
}

output "managed_devops_pool_subnet_id" {
  description = "ID of the Managed DevOps Pool subnet"
  value       = azapi_resource.managed_devops_pool_subnet.id
}

#-------------------------------------
# NAT Gateway Outputs
#------------------------------------
output "nat_gateway_id" {
  description = "ID of the NAT Gateway"
  value       = azurerm_nat_gateway.nat.id
}

output "nat_gateway_public_ip" {
  description = "Public IP address of the NAT Gateway"
  value       = azurerm_public_ip.nat_gateway.ip_address
}

#-------------------------------------
# NSG Outputs
#------------------------------------
output "nsg_ids" {
  description = "Map of NSG names to their IDs"
  value       = { for k, v in azurerm_network_security_group.nsgs : k => v.id }
}

output "nsg_names" {
  description = "Map of NSG keys to their names"
  value       = { for k, v in azurerm_network_security_group.nsgs : k => v.name }
}

#-------------------------------------
# Route Table Outputs
#------------------------------------
output "private_route_table_id" {
  description = "ID of the private subnet route table"
  value       = azurerm_route_table.private.id
}