#-------------------------------------
# RBAC Outputs
#------------------------------------
output "role_assignment_ids" {
  description = "Map of created role assignment IDs"
  value       = { for k, v in azurerm_role_assignment.role_assignments : k => v.id }
}

output "role_assignments_count" {
  description = "Number of role assignments created"
  value       = length(azurerm_role_assignment.role_assignments)
}
