#-------------------------------------
# Managed Identity
#------------------------------------
resource "azurerm_user_assigned_identity" "managed_identity" {
  name                = var.managed_identity_name
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags
}

#-------------------------------------
# Role Assignments for User Assigned Managed Identity
#------------------------------------
resource "azurerm_role_assignment" "managed_identity_role" {
  for_each = { for idx, assignment in var.role_assignments : idx => assignment }

  scope                = each.value.scope
  role_definition_name = each.value.role_definition_name
  principal_id         = azurerm_user_assigned_identity.managed_identity.principal_id
}


#-------------------------------------
# We need user-assigned managed identities for the following Azure DevOps Agent Pool types:
#
# ✅ `managed-devops-pools` (Microsoft-managed) - for when agents access our Azure resources
# ❌ `vmss-agent-pools` (Azure DevOps managed) - Uses system-assigned identity (automatically created)
# ✅ `vmss-classic-pools` (Self-managed) - for when we install the agent via a script - need a managed identity so the VM can access Azure resources (Key Vault, Storage, etc.) securely.
