# Lab: Variables and Locals

Duration: 15 minutes

We don't want to hard code all of our values into the main.tf file. We can use a variable file for easier use.

- Task 1: Variables in a configuration block
- Task 2: Interpolate those variables
- Task 3: Create a variables.tf file
- Task 4: Create a terraform.tfvars file
- Task 5: Create a locals block with common tags

## Create a variable declaration within a variables.tf file

### Task 1

Create a `variables.tf` file and place the following variable into the file:

```hcl
variable "location" {
  type = string
  description = "The Azure Region in which all resources in this example should be created. Defaults to East US."
  default = "East US"
}
```

### Task 2

Update your resource group to use the newly created variable.

```hcl
resource "azurerm_resource_group" "training" {
  name     = "###-resourcegroup"
  location = var.location
}
```

Run a `terraform plan` and validate that there are no changes.

```text
------------------------------------------------------------------------

No changes. Your infrastructure matches the configuration.

Terraform has compared your real infrastructure against your configuration and found no differences, so no changes are needed.
```

## Task 3: Add more input variables

Add the following variables to your variables.tf file:

```hcl
variable "resource_group_name" {
  type = string
  description = "The name of the resource group in which all resources in this example should be created."
}

variable "EnvironmentTag" {
  type = string
  description = "The environment tag for all resources in this example."
}

variable "prefix" {
  type = string
  description = "The prefix which should be used for all resources in this example. Set to your initials."
}

variable computer_name {
  type = string
  description = "The name of the virtual machine."
}

variable admin_username {
  type = string
  description = "The username of the virtual machine."
}

variable admin_password {
  type = string
  description = "The password of the virtual machine."
}
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

## Task 4: Refactor your configuration files to accept these variables

Update the `main.tf` file to use the variables.

```hcl
resource "azurerm_resource_group" "training" {
  name     = var.resource_group_name
  location = var.location
}
```

Update the vm.tf file to use the variables.

```hcl

resource "azurerm_virtual_machine" "training" {
  name                  = "${var.prefix}vm"
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

No changes. Your infrastructure matches the configuration.

Terraform has compared your real infrastructure against your configuration and found no differences, so no changes are needed.
```

## Task 5: Create a locals block with common tags

Create a `locals.tf` file and place the following code into the file:

```hcl
locals {
  common_tags = {
    environment = var.EnvironmentTag
    service_name = "Automation"
    owner        = "Cloud Team"
    createdby    = "terraform"
  }
}
```

Update the `vm.tf` file to use the locals.

```hcl

  tags = local.common_tags

```

Run a `terraform apply` to update the tags on the virtual machine.
