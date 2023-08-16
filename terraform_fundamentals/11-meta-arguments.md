# Lab: Meta-Arguments

Duration: 10 minutes

So far, we've already used arguments to configure your resources. These arguments are used by the provider to specify things like the image to use, and the type of instance to provision. Terraform also supports a number of _Meta-Arguments_, which change the way Terraform configures the resources. For instance, it's not uncommon to provision multiple copies of the same resource. We can do that with the _count_ argument.

- Task 1: Change the number of Virtual Machines with `count`
- Task 2: Modify the rest of the configuration to support multiple instances
- Task 3: Add variable interpolation to the count argument

## Task 1: Change the number of Azure Virtual Machines with `count`

We are going to reuse the configuration in the `azure` directory from the exercises `02-basic-configuration` and `03-virtual_machine`. If you don't have those configurations, they are in the appendix of this lab.

Add a count argument to the Azure Virtual Machine resource in `main.tf` with a value of 2.  Also adjust the value of `name` to incrementally add a number to the end of each instances name:

```hcl
# ...
resource "azurerm_virtual_machine" "training" {
  count                 = 2
  name                  = "${var.prefix}vm-${count.index + 1}"
  location              = azurerm_resource_group.training.location
  resource_group_name   = azurerm_resource_group.training.name
  network_interface_ids = [azurerm_network_interface.training[count.index].id]
  vm_size               = "Standard_D2s_v4"
# ...  

storage_os_disk {
    name              = "${var.prefix}disk-${count.index + 1}"
  # ... leave the rest of the resource block unchanged...
```

We also need to update the `azurerm_public_ip` and `azurerm_network_interface` resources to support the additional virtual machines.

```hcl
resource "azurerm_public_ip" "training" {
  count                   = 2
  name                    = "azureuser${var.prefix}ip-${count.index + 1}"
  location                = azurerm_resource_group.training.location
  resource_group_name     = azurerm_resource_group.training.name
  allocation_method       = "Dynamic"
  idle_timeout_in_minutes = 30
  domain_name_label       = "azureuser${var.prefix}domain${count.index + 1}"
}

resource "azurerm_network_interface" "training" {
  count               = 2
  name                = "azureuser${var.prefix}ni-${count.index + 1}"
  location            = azurerm_resource_group.training.location
  resource_group_name = azurerm_resource_group.training.name

  ip_configuration {
    name                          = "azureuser${var.prefix}ip"
    subnet_id                     = azurerm_subnet.training.id
    private_ip_address_allocation = "Dynamic"
    #private_ip_address            = "10.0.2.5"
    public_ip_address_id          = azurerm_public_ip.training[count.index].id
  }
}

```

## Task 2: Modify the rest of the configuration to support multiple instances

### Step 2.1

If you run `terraform apply` now, you'll get an error. Since we added _count_ to the azure_virtual_machine.training resource, it now refers to multiple resources. Because of this, values like our public_dns output no longer refer to the "public dns" of a single resource. We need to tell terraform which resource we're referring to.

To do so, modify the output blocks in `main.tf` as follows:

```hcl
output "public_dns" {
  value = azurerm_public_ip.training[*].fqdn
}
```

The syntax `azurerm_public_ip.training[*]...` refers to all of the instances, so this will output a list of all dns entries.

### Step 2.2

Run `terraform apply` to add the new instance. You will notice that because we changed the name of the Azure Virtual Mahine, that there will be a forced replacement of our previous virutal machine.

```text
Plan: 2 to add, 0 to change, 1 to destroy.
```

You should see two dns addresses in the outputs, one for each virtual machine.

```text
Plan: 2 to add, 0 to change, 1 to destroy.
```

## Task 3: Add variable interpolation to the count argument

### Step 3.1

Update `variables.tf` to add a new variable definition, and use it:

```hcl
variable "num_vms" {
  type = number
  default = 2
}
```

Update `main.tf`

```hcl
resource "azurerm_public_ip" "training" {
  count                   = var.num_vms
# ...

resource "azurerm_network_interface" "training" {
  count               = var.num_vms
# ...  

resource "azurerm_virtual_machine" "training" {
  count        = var.num_vms
# ...


```

The solution builds on our previous discussion of variables. We must create a variable to hold our count so that we can reference that count in our resource. Next, we replace the value of the count parameter with the variable
interpolation. Finally, we interpolate the current count (+ 1 because it's zero-indexed) and the variable itself.

Remember to also add the variable declaration to your `terraform.tfvars` accordingly.

```hcl
num_vms = 2
```

### Step 3.2

Run `terraform apply` in the terraform directory. No changes should be detected as the _values_ have not changed:

```shell
terraform apply
```

```text
No changes. Your infrastructure matches the configuration.

Terraform has compared your real infrastructure against your configuration and found no differences, so no changes are needed.
```

## Appendix

Here is the full configuration for the `azure` deployment before this lab in case you need it. It has been condensed into a single file for simplicity.

**`main.tf`**

```hcl
variable "location" {
  type        = string
  description = "The Azure Region in which all resources in this example should be created. Defaults to East US."
  default     = "East US"
}

variable "resource_group_name" {
  type        = string
  description = "The name of the resource group in which all resources in this example should be created."
}

variable "EnvironmentTag" {
  type        = string
  description = "The environment tag for all resources in this example."
}

variable "prefix" {
  type        = string
  description = "The prefix which should be used for all resources in this example. Set to your initials."
}

variable "computer_name" {
  type        = string
  description = "The name of the virtual machine."
}

variable "admin_username" {
  type        = string
  description = "The username of the virtual machine."
}

variable "admin_password" {
  type        = string
  description = "The password of the virtual machine."
}

locals {
  common_tags = {
    environment  = var.EnvironmentTag
    service_name = "Automation"
    owner        = "Cloud Team"
    createdby    = "terraform"
  }
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "training" {
  name     = var.resource_group_name
  location = var.location
}

resource "azurerm_virtual_network" "training" {
  name                = "azureusernsbvn"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.training.location
  resource_group_name = azurerm_resource_group.training.name
}

resource "azurerm_subnet" "training" {
  name                 = "azureusernsbsub"
  resource_group_name  = azurerm_resource_group.training.name
  virtual_network_name = azurerm_virtual_network.training.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_public_ip" "training" {
  name                    = "azureusernsbip"
  location                = azurerm_resource_group.training.location
  resource_group_name     = azurerm_resource_group.training.name
  allocation_method       = "Dynamic"
  idle_timeout_in_minutes = 30
  domain_name_label       = "azureusernsbdomain"
}

resource "azurerm_network_interface" "training" {
  name                = "azureusernsbni"
  location            = azurerm_resource_group.training.location
  resource_group_name = azurerm_resource_group.training.name

  ip_configuration {
    name                          = "azureusernsbip"
    subnet_id                     = azurerm_subnet.training.id
    private_ip_address_allocation = "Static"
    private_ip_address            = "10.0.2.5"
    public_ip_address_id          = azurerm_public_ip.training.id
  }
}

resource "azurerm_virtual_machine" "training" {
  name                  = "${var.prefix}vm"
  location              = azurerm_resource_group.training.location
  resource_group_name   = azurerm_resource_group.training.name
  network_interface_ids = [azurerm_network_interface.training.id]
  vm_size               = "Standard_D2s_v4"

  delete_os_disk_on_termination    = true
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

  tags = local.common_tags
}

output "public_dns" {
  value = azurerm_public_ip.training.fqdn
}
```

**`terraform.tfvars`**

```hcl
resource_group_name = "nsb-resourcegroup"
EnvironmentTag      = "staging"
prefix              = "###" # change to your initials
location            = "East US"
computer_name       = "myserver"
admin_username      = "testadmin"
admin_password      = "Password1234!"
```
