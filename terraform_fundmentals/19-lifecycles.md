# Lab: Lifecycles

Duration: 15 minutes

This lab demonstrates how to use lifecycle directives to control the order in which Terraform creates and destroys resources.

- Task 1: Use `create_before_destroy` with an instance rename
- Task 2: Use `prevent_destroy` with an instance

## Create the base Terraform Configuration

Change directory into a folder specific to this challenge, and create a `main.tf` and `terraform.tfvars` files to hold our configuration.

```shell
mkdir -p ~/workstation/terraform/azure/lifecycles/ && cd $_
touch main.tf
touch terraform.tfvars
```

We will start with a few of the basic resources needed.

## Task 1: Use `create_before_destroy` with an instance rename

When you rename a Azure Virtual Machine, terraform will reprovision the resource (delete and then create a new instance).  We can leverage `create_before_destroy` to override that default behavior

### Step 1.1: Deploy your Azure Virtual Machine

Place the following configuration in your `main.tf` file to deploy your virtual machine.

```hcl
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
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.main.id
  }
}

resource "azurerm_virtual_machine" "main" {
  name                  = "${var.prefix}-my-vm"
  location              = azurerm_resource_group.main.location
  resource_group_name   = azurerm_resource_group.main.name
  network_interface_ids = [azurerm_network_interface.main.id]
  vm_size               = var.vm_size
  
  delete_os_disk_on_termination = true

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
    admin_username = var.admin_username
    admin_password = var.admin_password
  }
}

resource "azurerm_public_ip" "main" {
  name                = "${var.prefix}-my-pubip"
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
```

Update your `terraform.tfvars` file with the following information, replacing ```###``` with your initials

```hcl
prefix              = "###"
location            = "East US"
admin_username      = "testadmin"
admin_password      = "Password1234!"
vm_size             = "Standard_A2_v2"
```

- Run a `terraform init`
- Run a `terraform plan`
- Run a `terraform apply`

### Step 1.2: Rename your Azure Virtual Machine

Edit your `main.tf` file and add the suffix _renamed_ to the value for `name` as shown below:

```hcl
resource "azurerm_virtual_machine" "main" {
  name         = "${var.prefix}-my-vm-renamed"
  ...
 
   
  storage_os_disk {
    name              = "${var.prefix}myvm-osdisk-renamed"
    ...
    
  
```

Run a `terraform apply` to see Terraform will _replace_ your instances by first deleting them and then recreating them:

```shell
terraform apply
```

```text
Resource actions are indicated with the following symbols:
-/+ destroy and then create replacement

Terraform will perform the following actions:

  # azurerm_virtual_machine.main must be replaced
  ```

Answer `yes` to proceed with the replacement of the instances.

### Step 1.3: Use `create_before_destroy` and rename the instances again

Add a `lifecycle` configuration to the `azurerm_virtual_machine` resource. Specify that this resource should be created before the existing instance(s) are destroyed.  Additionally, rename the instance(s) again, by removing the suffix _renamed_, and replacing it with `new`

```hcl
resource "azurerm_virtual_machine" "main" {
  name         = "${var.prefix}-my-vm-new"
  # ...
  
  storage_os_disk {
    name              = "${var.prefix}myvm-osdisk"
    ...
    
  lifecycle {
    create_before_destroy = true
  }
}
```

Also update the `azurerm_network_interface` with a lifecycle block and new name:

```hcl
resource "azurerm_network_interface" "main" {
  name                = "${var.prefix}-my-nic-new"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  ip_configuration {
    name                          = "config1"
    subnet_id                     = azurerm_subnet.main.id
    private_ip_address_allocation = "dynamic"
    public_ip_address_id          = azurerm_public_ip.main.id
  }
  
  lifecycle {
    create_before_destroy = true
  }
}
```

As well as the `azurerm_public_ip` with a lifecycle block and new name:

```hcl
resource "azurerm_public_ip" "main" {
  name                = "${var.prefix}-my-pubip-new"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  allocation_method   = "Static"
  
  lifecycle {
    create_before_destroy = true
  }
}
```

Now provision the new resources with the improved `lifecycle` configuration.

```shell
terraform apply
```

```shell
Resource actions are indicated with the following symbols:
+/- create replacement and then destroy

Terraform will perform the following actions:

  # azurerm_virtual_machine.main must be replaced
+/- resource "azurerm_virtual_machine" "main" {
```

## Task 2: Use `prevent_destroy` with an instance

We'll demonstrate how `prevent_destroy` can be used to guard an instance from being destroyed.

### Step 2.1: Use `prevent_destroy`

Add `prevent_destroy = true` to the same `lifecycle` stanza where you added `create_before_destroy`.

```hcl
resource "azurerm_virtual_machine" "main" {
  
  # ...

  lifecycle {
    create_before_destroy = true
    prevent_destroy = true
  }
}
```

Attempt to destroy the existing infrastructure. You should see the error that follows.

```bash
terraform destroy
```

```bash
Error: Instance cannot be destroyed

  on main.tf line 32:
  32: resource "azurerm_virtual_machine" "main" {

Resource azurerm_virtual_machine.main has
lifecycle.prevent_destroy set, but the plan calls for this resource to be
destroyed. To avoid this error and continue with the plan, either disable
lifecycle.prevent_destroy or reduce the scope of the plan using the -target
flag.
```

### Step 2.2: Destroy cleanly

Now that you have finished the steps in this lab, destroy the infrastructure you have created.

Remove the `prevent_destroy` attribute.

```hcl
resource "azurerm_virtual_machine" "main" {

  # ...

  lifecycle {
    create_before_destroy = true
    # Comment out or delete this line
    # prevent_destroy = true
  }
}
```

Finally, run `destroy`.

```shell
terraform destroy
```

The command should now succeed and your resources should be destroyed.
