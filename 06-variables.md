# Lab: Variables

Duration: 10 minutes

We don't want to hard code all of our values into the main.tf file. We can use a variable file for easier use.

- Task 1: Variables in a configuration block
- Task 2: Interpolate those variables
- Task 3: Create a variables.tf file
- Task 4: Create a terraform.tfvars file

### Create a variable declaration with your main.tf file

### Task 1
```hcl
variable "location" {
  default = "East US"
}
```

### Task 2

```hcl
resource "azurerm_resource_group" "training" {
  name     = "###-resourcegroup"
  location = var.location
}
```
Run a `terraform plan` and validate that there are no changes.

```text
------------------------------------------------------------------------

No changes. Infrastructure is up-to-date.

This means that Terraform did not detect any differences between your
configuration and real physical resources that exist. As a result, no
actions need to be performed.
```

## Task 3: Create a variables.tf file

Create a `variables.tf` file and place the following variables into the file.  Move the `location` variable out of `main.tf` and into `variables.tf`

```hcl
variable "resource_group_name" {}
variable "EnvironmentTag" {}
variable "prefix" {}
variable "location" {
  default = "East US"
}
variable computer_name {}
variable admin_username {}
variable admin_password {}
```
## Task 3: Create a terraform.tfvars file to specify the variable values

Create a `terraform.tfvars` file to specify the values for the declared variables above.

```hcl
resource_group_name = "<your_initials>-resourcegroup"
EnvironmentTag = "staging"
prefix = "<your_initials>"
location = "East US"
computer_name = "myserver"
admin_username = "testadmin"
admin_password = "Password1234!"
```

## Task 4: Refactor your main.tf file to accept these variables

```hcl
provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "training" {
  name     = var.resource_group_name
  location = var.location
}

...

resource "azurerm_virtual_machine" "training" {
  name                  = "${var.prefix}vm"
  location              = azurerm_resource_group.training.location
  resource_group_name   = azurerm_resource_group.training.name
  network_interface_ids = [azurerm_network_interface.training.id]
  vm_size               = "Standard_F2"

  delete_os_disk_on_termination = true
  delete_data_disks_on_termination = true

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }
  storage_os_disk {
    name              = "${var.prefix}disk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }
  os_profile {
    computer_name  = var.computer_name
    admin_username = var.admin_username
    admin_password = var.admin_password
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }

  tags = {
    environment = var.EnvironmentTag
  }
}
 
```

Run a `terraform plan` and validate that there are no changes.

```text
------------------------------------------------------------------------

No changes. Infrastructure is up-to-date.

This means that Terraform did not detect any differences between your
configuration and real physical resources that exist. As a result, no
actions need to be performed.
```
