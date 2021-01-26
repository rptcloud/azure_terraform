# Terraform Modules

## Expected Outcome

In this challenge, you will create a module to contain a scalable virtual machine deployment, then create an environment where you will call the module.

## How to

### Create Folder Structure

If you haven't already, `terraform destroy` your previous work.

Create and change directory into a folder specific to this challenge.

For example: `lab_exercise`

In order to organize your code inside the `lab_exercise` directory, create the following folder structure with `main.tf`, `variables.tf` and `terraform.tfvars` files.

```sh
lab_exercise
├── main.tf
├── modules
│   └── my_linux_vm
|          └── main.tf
├── terraform.tfvars
└── variables.tf
```

### Create the Module

Inside the `my_linux_vm` module folder create a `main.tf` file with the following contents:

> Note: This is very similar to the original VM lab.

```hcl
variable "prefix" {}
variable "location" {}
variable "username" {}
variable "vm_size" {}

provider "azurerm" {
  features {}
}

resource "random_password" "password" {
  length           = 16
  special          = true
  override_special = "!"
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

resource "azurerm_virtual_machine" "main" {
  name                  = "${var.prefix}-my-vm"
  location              = azurerm_resource_group.main.location
  resource_group_name   = azurerm_resource_group.main.name
  network_interface_ids = [azurerm_network_interface.main.id]
  vm_size               = var.vm_size

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  storage_os_disk {
    name              = "${var.prefix}myvm-osdisk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }

  os_profile {
    computer_name  = "${var.prefix}myvm"
    admin_username = var.username
    admin_password = random_password.password.result
  }
}

resource "azurerm_public_ip" "main" {
  name                = "${var.prefix}-my-pubip"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  allocation_method   = "Static"
}

output "vm-password" {
  value       = random_password.password.result
  description = "Dynamically generated password to access the VM."
}
output "private-ip" {
  value       = azurerm_network_interface.main.private_ip_address
  description = "Private IP Address"
}

output "public-ip" {
  value       = azurerm_public_ip.main.ip_address
  description = "Public IP Address"
}
```

### Create Variables in Root

In your root directory, there should be a `variables.tf` file.

Create "prefix", "location", and "username" variables without defaults.

This will result in them being required.

```hcl
variable "prefix" {}
variable "location" {}
variable "username" {}
```

> Extra credit: How many other variables can you extract?

### Pass in Variables

Create a file called 'terraform.tfvars' and add the following variables:
Make sure to replace "###" with your initials

```sh
prefix   = "###" 
location = "East US"
username = "Plankton"
```

### Create the Module declaration in Root

Update the root `main.tf` to declare your module, it should look similar to this:

```hcl
module "myawesomelinuxvm-a" {
  source   = "./modules/my_linux_vm"
}
```

> Notice the relative module sourcing.

### Terraform Init

Run `terraform init`.

```sh
Initializing modules...
- module.myawesomewindowsvm
  Getting source "./modules/my_linux_vm"
```

### Terraform Plan

Run `terraform plan`.

```sh

Error: Missing required argument

  on main.tf line 1, in module "myawesomelinuxvm-a":
   1: module "myawesomelinuxvm-a" {

The argument "prefix" is required, but no definition was found.


Error: Missing required argument

  on main.tf line 1, in module "myawesomelinuxvm-a":
   1: module "myawesomelinuxvm-a" {

The argument "location" is required, but no definition was found.


Error: Missing required argument

  on main.tf line 1, in module "myawesomelinuxvm-a":
   1: module "myawesomelinuxvm-a" {

The argument "username" is required, but no definition was found.


Error: Missing required argument

  on main.tf line 1, in module "myawesomelinuxvm-a":
   1: module "myawesomelinuxvm-a" {

The argument "vm_size" is required, but no definition was found.
```

We have a problem! We didn't set required variables for our module.

Update the `main.tf` file:

```hcl
module "myawesomelinuxvm-a" {
  source   = "./modules/my_linux_vm"
  prefix   = "${var.prefix}a"
  location = var.location
  username = var.username
  vm_size  = "Standard_A2_v2"
}
```

Run `terraform plan` again, this time there should not be any errors and you should see your VM built from your module.

```sh
  + module.myawesomelinuxvm-a.azurerm_resource_group.module
      id:                                 <computed>
      location:                           "eastus"

...

Plan: 7 to add, 0 to change, 0 to destroy.
```

## Add Another Module

Add another `module` block describing another set of Virtual Machines:

```hcl
module "myawesomelinuxvm-b" {
  source   = "./modules/my_linux_vm"
  prefix   = "${var.prefix}b"
  location = var.location
  username = var.username
  vm_size  = "Standard_A2_v2"
}
```

## Terraform Plan

Since we added another module call, we must run `terraform init` again before running `terraform plan`.

We should see twice as much infrastructure in our plan.

```sh
  # module.myawesomewindowsvm.azurerm_resource_group.main will be created
  + resource "azurerm_resource_group" "main" {
      + id       = (known after apply)
      + location = "eastus"
    }

...

  # module.differentwindowsvm.azurerm_resource_group.main will be created
  + resource "azurerm_resource_group" "main" {
      + id       = (known after apply)
      + location = "eastus"
    }

...

Plan: 14 to add, 0 to change, 0 to destroy.

```

## More Variables

In your `main.tf` file at the root we can see some duplication.

Extract "vm_size" into a local variable to your environment `main.tf` and reference in each module.

```hcl
locals {
  vm_size = "Standard_A2_v2"
}
```

Now reference them in the module blocks:

```hcl
module "myawesomelinuxvm-a" {
  ...
  vm_size = local.vm_size
}

module "myawesomelinuxvm-b" {
  ...
  vm_size = local.vm_size
}
```

## Terraform Plan

Run `terraform plan` and verify that your plan succeeds and looks the same.

Run `terraform apply` to build the infrastructure.

## Module Outputs

In your `main.tf` file at the root we query for the public IPs of the servers built within the module by creating output references to the public-ip value of the respective modules.

```hcl
output "public_ip_vm_a" {
    value = module.myawesomelinuxvm-a.public-ip
}

output "public_ip_vm_b" {
    value = module.myawesomelinuxvm-b.public-ip
}
```

Run `terraform refresh` to view these outputs.


## Cleanup 
Once complete, run a `terraform destroy` to tear down the infrastructure.

## Advanced areas to explore

1. Extract the Resource Group, Virtual Network, and Subnet into a "Networking" module and the Network Interface and Virtual Machine into a "VM" module and reference them with module declarations.
2. Update the VM module to use SSH instead of password authentication. 
3. Add a reference to the Public Terraform Module for [Azure Compute](https://registry.terraform.io/modules/Azure/compute/azurerm)

## Resources

- [Using Terraform Modules](https://www.terraform.io/docs/modules/usage.html)
- [Source Terraform Modiules](https://www.terraform.io/docs/modules/sources.html)
- [Public Module Registry](https://www.terraform.io/docs/registry/index.html)
- [locals](https://learn.hashicorp.com/tutorials/terraform/locals)
