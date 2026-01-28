#-------------------------------------
# RBAC Variables
#------------------------------------
variable "role_assignments" {
  description = "List of role assignments to create"
  type = list(object({
    principal_id         = string
    scope                = string
    role_definition_name = string
  }))
  default = []
}