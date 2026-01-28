#-------------------------------------
# Current Client Config
#------------------------------------
data "azurerm_client_config" "current" {}

#-------------------------------------
# Azure Key Vault
#-------------------------------------
resource "azurerm_key_vault" "kv" {
  name                          = var.key_vault_name
  location                      = var.location
  resource_group_name           = var.resource_group_name
  tenant_id                     = data.azurerm_client_config.current.tenant_id
  sku_name                      = var.key_vault_sku_name
  purge_protection_enabled      = var.purge_protection_enabled
  enable_rbac_authorization     = var.enable_rbac_authorization
  public_network_access_enabled = var.public_network_access_enabled

  network_acls {
    default_action             = var.network_acls_default_action
    bypass                     = var.network_acls_bypass
    virtual_network_subnet_ids = [var.private_subnet_id]
  }

  tags = var.tags
}

#-------------------------------------
# Private Endpoint for Key Vault
#-------------------------------------
resource "azurerm_private_endpoint" "kv_pe" {
  name                = var.private_endpoint_name
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.private_subnet_id

  private_service_connection {
    name                           = var.private_service_connection_name
    private_connection_resource_id = azurerm_key_vault.kv.id
    is_manual_connection           = var.is_manual_connection
    subresource_names              = var.subresource_names
  }

  private_dns_zone_group {
    name                 = var.private_dns_zone_group_name
    private_dns_zone_ids = [var.private_dns_zone_vault_id]
  }

  tags = var.tags
}

#-------------------------------------
# Key Vault Secrets
#-------------------------------------
resource "azurerm_key_vault_secret" "secrets" {
  for_each = var.key_vault_secrets

  name         = each.value.name
  value        = each.value.value
  key_vault_id = azurerm_key_vault.kv.id
}




# #-------------------------------------
# # Create Key Vault Secret for Azure DevOps PAT
# #-------------------------------------
# resource "azurerm_key_vault_secret" "devops_pat" {
#   name         = "azure-devops-pat-${var.environment}"
#   value        = var.pat_value
#   key_vault_id = azurerm_key_vault.kv.id
# }

# #-------------------------------------
# # Create Key Vault Secret for VMSS Agent Pool SP Client Secret
# #-------------------------------------
# resource "azurerm_key_vault_secret" "service_connection_sp_secret" {
#   name         = "service-connection-sp-secret-${var.environment}"
#   value        = var.client_secret_service_connection_sp != null ? var.client_secret_service_connection_sp : ""
#   key_vault_id = azurerm_key_vault.kv.id
# }

# #-------------------------------------
# # Create Key Vault Secret for SSH Public Key
# #-------------------------------------
# resource "azurerm_key_vault_secret" "admin_ssh_public_key" {
#   name         = "admin-ssh-public-key-${var.environment}"
#   value        = var.admin_ssh_public_key
#   key_vault_id = azurerm_key_vault.kv.id
# }
