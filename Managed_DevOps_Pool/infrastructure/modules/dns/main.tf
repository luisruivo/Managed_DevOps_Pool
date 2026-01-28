#-------------------------------------
# Private DNS Zones
#------------------------------------
resource "azurerm_private_dns_zone" "zone" {
  name                = var.private_dns_zone_name
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

#-------------------------------------
# VNet Links for Private DNS Zones
#------------------------------------
resource "azurerm_private_dns_zone_virtual_network_link" "vnet_link" {
  name                  = var.vnet_link_name
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.zone.name
  virtual_network_id    = var.vnet_id
  tags                  = var.tags
}
