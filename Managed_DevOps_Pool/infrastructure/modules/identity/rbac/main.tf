#-------------------------------------
# Role Assignment for RBAC - assigns existing roles (built-in or custom) to identities
#------------------------------------
resource "azurerm_role_assignment" "role_assignments" {
  for_each = { for idx, assignment in var.role_assignments : idx => assignment }

  scope                = each.value.scope
  principal_id         = each.value.principal_id
  role_definition_name = each.value.role_definition_name
}