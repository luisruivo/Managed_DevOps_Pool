#-------------------------------------
# Resource Group
#------------------------------------
resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location

  lifecycle {
    prevent_destroy = true
  }

  tags = var.tags
}
