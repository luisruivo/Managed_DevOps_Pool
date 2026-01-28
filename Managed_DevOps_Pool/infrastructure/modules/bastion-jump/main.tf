#-------------------------------------
# Bastion Jump VM
#-------------------------------------
resource "azurerm_linux_virtual_machine" "bastion_jump" {
  name                = var.bastion_name
  resource_group_name = var.resource_group_name
  location            = var.location
  size                = var.bastion_vm_size
  admin_username      = var.bastion_admin_username

  disable_password_authentication = true

  network_interface_ids = [
    azurerm_network_interface.bastion_jump.id,
  ]

  admin_ssh_key {
    username   = var.bastion_admin_username
    public_key = var.admin_ssh_public_key
  }

  os_disk {
    caching              = var.bastion_os_disk_caching
    storage_account_type = var.bastion_os_disk_storage_account_type
  }

  source_image_reference {
    publisher = var.bastion_image_publisher
    offer     = var.bastion_image_offer
    sku       = var.bastion_image_sku
    version   = var.bastion_image_version
  }

  tags = var.tags
}


#-------------------------------------
# Public IP for Bastion Jump VM
#-------------------------------------
resource "azurerm_public_ip" "bastion_jump" {
  name                = var.bastion_public_ip_name
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

#-------------------------------------
# Network Interface for Bastion Jump VM
#-------------------------------------
resource "azurerm_network_interface" "bastion_jump" {
  name                = var.bastion_network_interface_name
  location            = var.location
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = var.public_subnet_id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.bastion_jump.id
  }

  tags = var.tags
}
