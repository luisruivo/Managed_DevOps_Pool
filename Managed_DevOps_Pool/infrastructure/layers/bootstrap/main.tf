#-------------------------------------
# Reusable Modules
#------------------------------------
module "resource_groups" {
  source   = "../../modules/resource-group"
  for_each = var.resource_groups

  resource_group_name = "rg-${var.environment}-${each.value.suffix_name}"
  location            = each.value.location
  tags                = merge(var.tags, each.value.specific_tags)
}

module "storage_accounts" {
  source   = "../../modules/storage-account"
  for_each = var.storage_accounts

  storage_account_name            = "saluis${var.environment}${each.value.suffix_name}"
  account_tier                    = var.account_tier
  account_replication_type        = var.account_replication_type
  min_tls_version                 = var.min_tls_version
  public_network_access_enabled   = var.public_network_access_enabled
  network_rules_default_action    = var.network_rules_default_action
  network_rules_bypass            = var.network_rules_bypass
  blob_versioning_enabled         = var.blob_versioning_enabled
  containers                      = each.value.containers
  container_access_type           = var.container_access_type
  enable_private_endpoint         = var.enable_private_endpoint
  private_endpoint_name           = each.value.private_endpoint_name
  private_service_connection_name = each.value.private_service_connection_name
  is_manual_connection            = var.is_manual_connection
  subresource_names               = var.subresource_names
  blob_dns_zone_group_name        = var.blob_dns_zone_group_name

  private_subnet_id        = var.private_subnet_id
  private_dns_zone_blob_id = var.private_dns_zone_blob_id

  location            = var.location
  resource_group_name = module.resource_groups[each.value.resource_group_key].resource_group_name
  tags                = merge(var.tags, each.value.specific_tags)

  depends_on = [module.resource_groups]
}
