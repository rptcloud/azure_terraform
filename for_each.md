# Lab: For-Each

Duration: 15 minutes

So far, we've already used arguments to configure your resources. These arguments are used by the provider to specify things like the image to use, and the type of instance to provision. Terraform also supports a number of _Meta-Arguments_, which changes the way Terraform configures the resources. For instance, it's not uncommon to provision multiple copies of the same resource. We can do that with the _count_ argument.

The count argument does however have a few limitations in that it is entirely dependent on the count index which can be shown by performing a `terraform state list`.

A more mature approach to create multiple instances while keeping code DRY is to leverage Terraform's `for-each`.

- Task 1: Change the number of VM instances with `count`
- Task 2: Look at the number of VM instances with `terraform state list`
- Task 3: Decrease the Count and determine which instance will be destroyed.
- Task 4: Refactor code to use Terraform `for-each`
- Task 5: Look at the number of VM instances with `terraform state list`
- Task 6: Update the output variables to pull IP and DNS addresses.
- Task 7: Update the server variables to determine which instance will be destroyed.

## Task 1: Change the number of VM instances with `count`

Change directory into a folder specific to this challenge.

For example: `cd /workstation/terraform/azure/for_each/`.

We will start with a few of the basic resources needed.

Create a `variables.tf`, `main.tf`, `outputs.tf` and `terraform.tfvars` files to hold our configuration.

Update the root `main.tf` to utilize the `count` paramater on the VM resource.  Notice the count has been variablized to specify the number of VMs.

`main.tf`

```hcl
provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "training" {
  name     = "${var.prefix}-resourcegroup"
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
    #private_ip_address            = "10.0.2.5"
    public_ip_address_id = azurerm_public_ip.training[count.index].id
  }
}

resource "azurerm_virtual_machine" "training" {
  count                 = var.num_vms
  name                  = "${var.prefix}vm-${count.index + 1}"
  location              = azurerm_resource_group.training.location
  resource_group_name   = azurerm_resource_group.training.name
  network_interface_ids = [azurerm_network_interface.training[count.index].id]
  vm_size               = "Standard_A2_v2"

  delete_os_disk_on_termination    = true
  delete_data_disks_on_termination = true

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"

  }
  storage_os_disk {
    name              = "${var.prefix}disk-${count.index + 1}"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name  = "${var.prefix}myserver"
    admin_username = var.admin_username
    admin_password = var.admin_password
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }

  tags = {
    environment = "staging"
  }
}
```

`outputs.tf`
```hcl
output "public_dns" {
  value = azurerm_public_ip.training[*].fqdn
}
```

`variables.tf`
```hcl
variable "prefix" {
  default     = "<initials>"
  type        = string
  description = "Prefix to append to resources"
}

variable "location" {
  type        = string
  description = "Azure location"
  default     = "East US"
}

variable "admin_username" {
  type        = string
  description = "Server Admin Username"
}
variable "admin_password" {
  type        = string
  description = "Server Admin Password"
}

variable "num_vms" {
  default = 2
}
```

`terraform.tfvars`

```hcl
prefix         = "ghm"
location       = "East US"
admin_username = "testadmin"
admin_password = "Password1234!"
num_vms        = 2
```

## Task 2: Look at the number of servers with `terraform state list`

```bash
terraform state list

azurerm_network_interface.training[0]
azurerm_network_interface.training[1]

azurerm_public_ip.training[0]
azurerm_public_ip.training[1]


azurerm_virtual_machine.training[0]
azurerm_virtual_machine.training[1]

```

Notice the way resources are indexed when using meta-arguments.

## Task 3: Decrease the Count and determine which instance will be destroyed.

Update the count from `2` to `1` by changing the `num_vms` variable in your `terraform.tfvars` file.

```hcl
prefix         = "ghm"
location       = "East US"
admin_username = "testadmin"
admin_password = "Password1234!"
num_vms        = 1
```

Run a `terraform apply` followed by a `terraform state list` to view how the servers are accounted for in Terraform's State.

```bash
terraform apply
```

```
terraform state list

azurerm_network_interface.training[0]
azurerm_public_ip.training[0]
azurerm_resource_group.training
azurerm_subnet.training
azurerm_virtual_machine.training[0]
azurerm_virtual_network.training
```

You will see that when using the `count` parameter you have very limited control as to which server Terraform will destroy. It will always default to destroying the server with the highest index count.

## Task 4: Refactor code to use Terraform `for-each`

Refactor `main.tf` to make use of the `for-each` command rather then the count command. Replace the following in the `main.tf` and comment out the `output` blocks for now.

```hcl
locals {
  servers = {
    server-ubuntu-16 = {
      identity  = "${var.prefix}-ubuntu-16"
      publisher = "Canonical"
      offer     = "UbuntuServer"
      sku       = "16.04-LTS"
      version   = "latest"
    },
    server-ubuntu-18 = {
      identity  = "${var.prefix}-ubuntu-18"
      publisher = "Canonical"
      offer     = "UbuntuServer"
      sku       = "18.04-LTS"
      version   = "latest"
    },
  }
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "training" {
  name     = "${var.prefix}-resourcegroup"
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
  for_each                = local.servers
  name                    = "azureuser${var.prefix}ip-${each.value.identity}"
  location                = azurerm_resource_group.training.location
  resource_group_name     = azurerm_resource_group.training.name
  allocation_method       = "Dynamic"
  idle_timeout_in_minutes = 30
  domain_name_label       = "azureuser${var.prefix}domain-${each.key}"
}

resource "azurerm_network_interface" "training" {
  for_each            = local.servers
  name                = "azureuser${var.prefix}ni-${each.value.identity}"
  location            = azurerm_resource_group.training.location
  resource_group_name = azurerm_resource_group.training.name

  ip_configuration {
    name                          = "azureuser${var.prefix}ip"
    subnet_id                     = azurerm_subnet.training.id
    private_ip_address_allocation = "dynamic"
    #private_ip_address            = "10.0.2.5"
    public_ip_address_id = azurerm_public_ip.training[each.key].id
  }
}

resource "azurerm_virtual_machine" "training" {
  for_each              = local.servers
  name                  = "${var.prefix}vm-${each.value.identity}"
  location              = azurerm_resource_group.training.location
  resource_group_name   = azurerm_resource_group.training.name
  network_interface_ids = [azurerm_network_interface.training[each.key].id]
  vm_size               = "Standard_A2_v2"

  delete_os_disk_on_termination    = true
  delete_data_disks_on_termination = true

  storage_image_reference {

    publisher = each.value.publisher
    offer     = each.value.offer
    sku       = each.value.sku
    version   = each.value.version

  }
  storage_os_disk {
    name              = "${var.prefix}disk-${each.value.identity}"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name  = "${var.prefix}myserver"
    admin_username = var.admin_username
    admin_password = var.admin_password
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }

  tags = {
    environment = "staging"
  }
}
```

If you run `terraform apply` now, you'll notice that this code will destroy the previous resource and create two new servers based on the attributes defined inside the `servers` variable, which is defined as a map of our servers.

### Task 5: Look at the number of VM instances with `terraform state list`

```bash
terraform state list

azurerm_network_interface.training["server-ubuntu-16"]
azurerm_network_interface.training["server-ubuntu-18"]
azurerm_public_ip.training["server-ubuntu-16"]
azurerm_public_ip.training["server-ubuntu-18"]
azurerm_resource_group.training
azurerm_subnet.training
azurerm_virtual_machine.training["server-ubuntu-16"]
azurerm_virtual_machine.training["server-ubuntu-18"]
azurerm_virtual_network.training
```

Since we used _for-each_ to the azurerm_virtual_machine.training resource, it now refers to multiple resources with key references from the `servers` variable.

### Task 6: Update the output variables to pull IP and DNS addresses.

When using Terraform's `for-each` our output blocks need to be updated to utilize `for` to loop through the server names. This differs from using `count` which utilized the Terraform splat operator `*`. Uncomment and update the output block of your `main.tf`.

```hcl
output "public_dns" {
  description = "Public DNS names of the Servers"
  value       = { for p in sort(keys(local.servers)) : p => azurerm_public_ip.training[p].fqdn }
}
```

Format, validate and apply your configuration to now see the format of the Outputs.

```
terraform fmt
terraform validate
terraform apply
```

```bash
public_dns = {
  "server-ubuntu-16" = "azureuserghmdomain-server-ubuntu-16.eastus.cloudapp.azure.com"
  "server-ubuntu-18" = "azureuserghmdomain-server-ubuntu-18.eastus.cloudapp.azure.com"
}
```

## Task 7: Update the server variables to determine which instance will be destroyed.

Update the `servers` local variable to remove the `server-ubuntu-16` instance by removing the following block:

```hcl
    server-ubuntu-16 = {
      identity  = "${var.prefix}-ubuntu-16"
      publisher = "Canonical"
      offer     = "UbuntuServer"
      sku       = "16.04-LTS"
      version   = "latest"
    },
```

If you run `terraform apply` now, you'll notice that this code will destroy the `server-ubuntu-16`, allowing us to target a specific instance that needs to be updated/removed.
