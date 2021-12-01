# Lab: Local Variables

Duration: 15 minutes

A local value assigns a name to an expression, so you can use it multiple times within a module without repeating it. The expressions in local values are not limited to literal constants; they can also reference other values in the module in order to transform or combine them, including variables, resource attributes, or other local values.

- Task 1: Create local variables in a configuration block
- Task 2: Interpolate local variables
- Task 3: Using locals with variable expressions

## Task 1: Create local variables in a configuration block

Add local variables to a `local.tf` file:

```hcl
locals {
  service_name = "Automation"
  owner        = "Cloud Team"
  createdby    = "terraform"
}
```

Add input variables to a `variables.tf` file:

```hcl
variable "resource_group_name" {}
variable "EnvironmentTag" {}
variable "prefix" {}
variable "location" {
  default = "East US"
}
variable "computer_name" {}
variable "admin_username" {}
variable "admin_password" {}
variable "num_vms" {
  default = 2
}
```

Add a `terraform.tfvars` file:
  
```hcl
resource_group_name = "ghm-resourcegroup-locals"
EnvironmentTag      = "staging"
prefix              = "ghm"
location            = "East US"
computer_name       = "myserver"
admin_username      = "testadmin"
admin_password      = "Password1234!"
num_vms             = 1
```
  
## Task 2: Interpolate local variables into your code

Create a `main.tf` to add new tags to all instances using local variable interpolation.

```hcl
provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "training" {
  name     = var.resource_group_name
  location = var.location
}

resource "azurerm_virtual_network" "training" {
  name                = "azureuser${var.prefix}vn"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.training.location
  resource_group_name = azurerm_resource_group.training.name
}

resource "azurerm_subnet" "training" {
  name                 = "azureuser${var.prefix}sub"
  resource_group_name  = azurerm_resource_group.training.name
  virtual_network_name = azurerm_virtual_network.training.name
  address_prefixes     = ["10.0.2.0/24"]
}


resource "azurerm_public_ip" "training" {
  count                   = var.num_vms
  name                    = "azureuser${var.prefix}ip-${count.index + 1}"
  location                = azurerm_resource_group.training.location
  resource_group_name     = azurerm_resource_group.training.name
  allocation_method       = "Dynamic"
  idle_timeout_in_minutes = 30
  domain_name_label       = "azureuser${var.prefix}domain${count.index + 1}"
}

resource "azurerm_network_interface" "training" {
  count               = var.num_vms
  name                = "azureuser${var.prefix}ni-${count.index + 1}"
  location            = azurerm_resource_group.training.location
  resource_group_name = azurerm_resource_group.training.name

  ip_configuration {
    name                          = "azureuser${var.prefix}ip"
    subnet_id                     = azurerm_subnet.training.id
    private_ip_address_allocation = "dynamic"
    public_ip_address_id          = azurerm_public_ip.training[count.index].id
  }
}

resource "azurerm_virtual_machine" "training" {
  count                 = var.num_vms
  name                  = "${var.prefix}vm-${count.index + 1}"
  location              = azurerm_resource_group.training.location
  resource_group_name   = azurerm_resource_group.training.name
  network_interface_ids = [azurerm_network_interface.training[count.index].id]
  vm_size               = "Standard_F2"

  delete_os_disk_on_termination    = true
  delete_data_disks_on_termination = true

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }
  storage_os_disk {
    name              = "${var.prefix}disk-${count.index + 1}"
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

  tags = local.common_tags
}
```
  
  

After making these changes, rerun `terraform plan`. You should see that there will be some tagging updates to your server instances. Execute a `terraform apply` to make these changes.

## Task 3: Using locals with variable expressions

Expressions in local values are not limited to literal constants; they can also reference other values in the module in order to transform or combine them, including variables, resource attributes, or other local values.

Add another local variable block to your `locals.tf` configuration which references the local variables set in the previous portion of the lab.

```hcl
locals {
  # Common tags to be assigned to all resources
  common_tags = {
    Name        = var.identity
    Environment = var.environment
    createdby = local.createdby
    Service = local.service_name
    Owner   = local.owner
  }
}
```

Update the `azurerm_virtual_machine` tags block inside your `main.tf` to reference the `local.common_tags` variable.

```hcl
resource "azurerm_virtual_machine" "training" {
  count                 = var.num_vms
  name                  = "${var.prefix}vm-${count.index + 1}"
  location              = azurerm_resource_group.training.location
  resource_group_name   = azurerm_resource_group.training.name
  network_interface_ids = [azurerm_network_interface.training[count.index].id]
  vm_size               = "Standard_F2"

  delete_os_disk_on_termination    = true
  delete_data_disks_on_termination = true

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }
  storage_os_disk {
    name              = "${var.prefix}disk-${count.index + 1}"
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

  tags = local.common_tags
}
```

After making these changes, rerun `terraform plan`. You should see that there are no changes to apply, which is correct, since the variables contain the same values we had previously hard-coded, but now that are referenced via locals.

```text
...

No changes. Infrastructure is up-to-date.

This means that Terraform did not detect any differences between your
configuration and real physical resources that exist. As a result, no
actions need to be performed.
```

Local values can be helpful to avoid repeating the same values or expressions multiple times in a configuration, but if overused they can also make a configuration hard to read by future maintainers by hiding the actual values used.

Use local values only in moderation, in situations where a single value or result is used in many places and that value is likely to be changed in future. The ability to easily change the value in a central place is the key advantage of local values.
