variable "prefix" {}
variable "location" {}
variable "admin_username" {}
variable "admin_password" {}
variable "vm_size" {}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "main" {
  location = var.location
  name     = "${var.prefix}-my-rg"
}

resource "azurerm_virtual_network" "main" {
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  name                = "${var.prefix}-my-vnet"
  address_space       = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "main" {
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  name                 = "${var.prefix}-my-subnet"
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_network_interface" "main" {
  name                = "${var.prefix}-my-nic"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  ip_configuration {
    name                          = "config1"
    subnet_id                     = azurerm_subnet.main.id
    private_ip_address_allocation = "dynamic"
    public_ip_address_id          = azurerm_public_ip.main.id
  }
}

resource "azurerm_network_interface" "new" {
  name                = "${var.prefix}-my-nic-new"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  ip_configuration {
    name                          = "config1"
    subnet_id                     = azurerm_subnet.main.id
    private_ip_address_allocation = "dynamic"
    public_ip_address_id          = azurerm_public_ip.new.id
  }
}

resource "azurerm_virtual_machine" "main" {
  name                  = "${var.prefix}-my-vm-renamed"
  location              = azurerm_resource_group.main.location
  resource_group_name   = azurerm_resource_group.main.name
  network_interface_ids = [azurerm_network_interface.new.id]
  vm_size               = var.vm_size

  delete_os_disk_on_termination = true

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  storage_os_disk {
    name              = "${var.prefix}myvm-osdisk-renamed"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }

  os_profile {
    computer_name  = "${var.prefix}myvm"
    admin_username = var.admin_username
    admin_password = var.admin_password
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "azurerm_public_ip" "main" {
  name                = "${var.prefix}-my-pubip"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  allocation_method   = "Static"
}

resource "azurerm_public_ip" "new" {
  name                = "${var.prefix}-my-pubip-new"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  allocation_method   = "Static"
}

output "private-ip" {
  value       = azurerm_network_interface.main.private_ip_address
  description = "Private IP Address"
}

output "public-ip" {
  value       = azurerm_public_ip.main.ip_address
  description = "Public IP Address"
}
