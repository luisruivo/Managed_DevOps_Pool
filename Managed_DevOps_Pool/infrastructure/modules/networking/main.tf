#-------------------------------------
# Terraform Configuration
#------------------------------------
terraform {
  required_providers {
    azapi = {
      source  = "azure/azapi"
      version = "2.5.0"
    }
  }
}

#-------------------------------------
# Local Values
#------------------------------------
locals {
  nat_gateway_subnet_associations = merge(
    {
      for key, subnet in azurerm_subnet.subnets : key => subnet.id
      if key == "private" # Only associate private subnets from the regular subnets
    },
    {
      managed_devops_pool = azapi_resource.managed_devops_pool_subnet.id
    }
  )

  all_subnets_for_nsg = merge(
    {
      for key, subnet in azurerm_subnet.subnets : key => {
        subnet_id = subnet.id
        nsg_type  = key == "public" ? "public" : "private"
      }
    },
    {
      managed_devops_pool = {
        subnet_id = azapi_resource.managed_devops_pool_subnet.id
        nsg_type  = "private"
      }
    }
  )

  private_subnets_for_route_table = merge(
    {
      for key, subnet in azurerm_subnet.subnets : key => subnet.id
      if key == "private"
    },
    {
      managed_devops_pool = azapi_resource.managed_devops_pool_subnet.id
    }
  )
}

#-------------------------------------
# Virtual Network (VNet)
#------------------------------------
resource "azurerm_virtual_network" "vnet" {
  name                = var.vnet_name
  location            = var.location
  resource_group_name = var.resource_group_name
  address_space       = var.vnet_address_space

  tags = var.tags
}

#-------------------------------------
# Subnets
#------------------------------------
resource "azurerm_subnet" "subnets" {
  for_each = var.subnets

  name                 = each.value.name
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = each.value.address_prefixes
  service_endpoints    = each.value.service_endpoints

  # Optional delegations
  dynamic "delegation" {
    for_each = each.value.delegations
    content {
      name = delegation.value.name
      service_delegation {
        name    = delegation.value.service_name
        actions = delegation.value.actions
      }
    }
  }
}

#-------------------------------------
# Managed DevOps Pool Subnet (using azapi for delegation support as the resource azurerm_subnet does not support Microsoft.DevOpsInfrastructure/pools)
#------------------------------------
resource "azapi_resource" "managed_devops_pool_subnet" {
  name      = var.managed_devops_pool_subnet_name
  type      = var.managed_devops_pool_subnet_type
  parent_id = azurerm_virtual_network.vnet.id

  body = {
    properties = {
      addressPrefix = var.managed_devops_pool_subnet_address_prefixes[0] # azapi_resource uses the raw Azure API addressPrefix (singular, expects string - that's why [0] at the end) but azurerm_subnet uses address_prefixes (plural, accepts list)

      serviceEndpoints = [
        for s in var.managed_devops_pool_subnet_service_endpoints : { service = s }
      ]

      delegations = [
        {
          name = var.managed_devops_pool_subnet_delegation_name
          properties = {
            serviceName = var.managed_devops_pool_subnet_delegation_service_name
          }
        }
      ]
    }
  }

  depends_on = [azurerm_virtual_network.vnet]
}

#-------------------------------------
# NAT Gateway
#------------------------------------
resource "azurerm_nat_gateway" "nat" {
  name                    = var.nat_gateway_name
  location                = var.location
  resource_group_name     = var.resource_group_name
  sku_name                = var.nat_sku_name
  idle_timeout_in_minutes = var.idle_timeout_in_minutes # If no data sent or received for 10 minutes, the connection will be closed
  zones                   = var.zones

  tags = var.tags
}

#-------------------------------------
# Public IP for NAT Gateway
#------------------------------------
resource "azurerm_public_ip" "nat_gateway" {
  name                = var.nat_gateway_public_ip_name
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = var.allocation_method
  sku                 = var.nat_sku_name
  zones               = var.zones

  tags = var.tags
}

#-------------------------------------
# NAT Gateway Public IP Association
#------------------------------------
resource "azurerm_nat_gateway_public_ip_association" "nat" {
  nat_gateway_id       = azurerm_nat_gateway.nat.id
  public_ip_address_id = azurerm_public_ip.nat_gateway.id
}

#-------------------------------------
# NAT Gateway Subnet Associations
#------------------------------------
resource "azurerm_subnet_nat_gateway_association" "subnets" {
  for_each = local.nat_gateway_subnet_associations

  subnet_id      = each.value
  nat_gateway_id = azurerm_nat_gateway.nat.id
}

#-------------------------------------
# Network Security Groups
#------------------------------------
resource "azurerm_network_security_group" "nsgs" {
  for_each = var.nsg_configs

  name                = each.value.name
  location            = var.location
  resource_group_name = var.resource_group_name

  dynamic "security_rule" {
    for_each = each.value.rules
    content {
      name                       = security_rule.value.name
      priority                   = security_rule.value.priority
      direction                  = security_rule.value.direction
      access                     = security_rule.value.access
      protocol                   = security_rule.value.protocol
      source_port_range          = security_rule.value.source_port_range
      destination_port_range     = security_rule.value.destination_port_range
      source_address_prefix      = security_rule.value.source_address_prefix
      destination_address_prefix = security_rule.value.destination_address_prefix
    }
  }

  tags = var.tags
}

#-------------------------------------
# NSG Associations
#------------------------------------
resource "azurerm_subnet_network_security_group_association" "all_subnets" {
  for_each = local.all_subnets_for_nsg

  subnet_id                 = each.value.subnet_id
  network_security_group_id = azurerm_network_security_group.nsgs[each.value.nsg_type].id
}

#-------------------------------------
# Route Table for Private Subnet
#------------------------------------
resource "azurerm_route_table" "private" {
  name                = var.private_subnet_route_table_name
  location            = var.location
  resource_group_name = var.resource_group_name

  tags = var.tags
}

#-------------------------------------
# Route Table Association - Private Subnet
#------------------------------------
resource "azurerm_subnet_route_table_association" "private_subnets" {
  for_each = local.private_subnets_for_route_table

  subnet_id      = each.value
  route_table_id = azurerm_route_table.private.id
}
