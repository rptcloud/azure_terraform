# Lab: Virtual Machine

Duration: 10 minutes

- Task 1: Create an Azure Virtual Machine using underlying network infrastructure.

## Task 1: Azure virtual machine
# When cutting/pasting to create or update your tf file, but sure to replace "###" with your initials

### 1. With an underlying network infrastructure, we can begin to build our virtual machine that will host our webapp.

Append the following into your `main.tf`

```
resource "azurerm_virtual_machine" "training" {
  name                  = "###vm"
  location              = azurerm_resource_group.training.location
  resource_group_name   = azurerm_resource_group.training.name
  network_interface_ids = [azurerm_network_interface.training.id]
  vm_size               = "Standard_D2s_v4"

  delete_os_disk_on_termination = true
  delete_data_disks_on_termination = true

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"

  }
  storage_os_disk {
    name              = "###disk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name  = "myserver"
    admin_username = "testadmin"
    admin_password = "Password1234!"
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }

  tags = {
    environment = "staging"
  }
}
```

### 2. Run `terraform plan` to view the resources that will be created
### 3. Run `terraform apply` to create the resources specified