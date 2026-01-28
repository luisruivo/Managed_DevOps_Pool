#-------------------------------------
# Storage Account
#------------------------------------
resource "azurerm_storage_account" "sa" {
  name                          = var.storage_account_name
  resource_group_name           = var.resource_group_name
  location                      = var.location
  account_tier                  = var.account_tier
  account_replication_type      = var.account_replication_type
  min_tls_version               = var.min_tls_version
  public_network_access_enabled = var.public_network_access_enabled

  network_rules {
    default_action             = var.network_rules_default_action
    bypass                     = var.network_rules_bypass
    virtual_network_subnet_ids = var.private_subnet_id != null && var.private_subnet_id != "" ? [var.private_subnet_id] : []
  }

  blob_properties {
    versioning_enabled = true
  }

  lifecycle {
    ignore_changes = [network_rules]
  }

  tags = var.tags
}

#-------------------------------------
# Blob Containers
#------------------------------------
resource "azurerm_storage_container" "containers" {
  for_each = var.containers

  name                  = each.value.name
  storage_account_id    = azurerm_storage_account.sa.id
  container_access_type = coalesce(each.value.container_access_type, var.container_access_type)
}

#-------------------------------------
# Private Endpoint for Storage Account
#------------------------------------
resource "azurerm_private_endpoint" "storage_pe" {
  count               = var.enable_private_endpoint && var.private_subnet_id != "" && var.private_dns_zone_blob_id != "" ? 1 : 0 # Only create if private endpoint is enabled and required IDs are provided (prevents errors during bootstrap layer creation).
  name                = var.private_endpoint_name
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.private_subnet_id

  private_service_connection {
    name                           = var.private_service_connection_name
    private_connection_resource_id = azurerm_storage_account.sa.id
    is_manual_connection           = var.is_manual_connection
    subresource_names              = var.subresource_names
  }

  private_dns_zone_group {
    name                 = var.blob_dns_zone_group_name
    private_dns_zone_ids = [var.private_dns_zone_blob_id]
  }

  tags = var.tags
}

#--------------------------------------
# account_replication_type:
# LRS (Locally Redundant Storage): Data is replicated three times within a single Azure datacenter in one region, providing protection against hardware failures but not against datacenter outages.
# GRS (Geo-Redundant Storage): Data is replicated to a secondary region hundreds of miles away from the primary location, providing higher durability in case of a regional outage.
# ZRS (Zone-Redundant Storage): Data is replicated across multiple availability zones within a region, offering high availability and resiliency to zone failures.