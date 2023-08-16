# Lab: Null Resource

Duration: 15 minutes

This lab demonstrates the use of the `null_resource`. Instances of `null_resource` are treated like normal resources, but they don't do anything. Like with any other resource, you can configure provisioners and connection details on a null_resource. You can also use its triggers argument and any meta-arguments to control exactly where in the dependency graph its provisioners will run.

- Task 1: Create a Azure Virtual Macine using Terraform
- Task 2: Use `null_resource` with a VM to take action with `triggers`.

We'll demonstrate how `null_resource` can be used to take action on a set of existing resources that are specified within the `triggers` argument

## Task 1: Create a Azure Virtual Machine using Terraform

### Step 1.1: Create Server instances

Build the web servers using the Azure Virtual Machine resource:

Create the folder structure:

```bash
mkdir ~/workstation/terraform/null_resource && cd $_
touch {variables,main,terraform}.tf
touch terraform.tfvars
```

Add the following to the `terraform.tf` file:

```hcl
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.0"
    }
  }
}
```

Update your `main.tf` with the following:

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
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.training[count.index].id
  }
}

resource "azurerm_virtual_machine" "training" {
  count                 = var.num_vms
  name                  = "${var.prefix}vm-${count.index + 1}"
  location              = azurerm_resource_group.training.location
  resource_group_name   = azurerm_resource_group.training.name
  network_interface_ids = [azurerm_network_interface.training[count.index].id]
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

  tags = {
    environment = var.EnvironmentTag
  }
}

```

Update your `variables.tf` with the following:

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

Update or your `terraform.tfvars` with the following and replace the `###` with your initials:

```hcl
resource_group_name = "###-nullrg"
EnvironmentTag = "staging"
prefix = "###"
location = "East US"
computer_name = "myserver"
admin_username = "testadmin"
admin_password = "Password1234!"
num_vms = 1
```

Then perform an `init`, `plan`, and `apply`.

## Task 2: Use `null_resource` with a Azure Virtual Machine to take action with `triggers`

### Step 2.1: Use `null_resource`

Add the `null_resource` block to the `main.tf`.  Notice that the trigger for this resource is set to monitor changes to the number of virtual machines.

```hcl
resource "null_resource" "web_cluster" {
  # Changes to any instance of the cluster requires re-provisioning
  triggers = {
    web_cluster_size = join(",",azurerm_virtual_machine.training.*.id)
  }

  # Bootstrap script can run on any instance of the cluster
  # So we just choose the first in this case
  connection {
    host = element(azurerm_public_ip.training.*.ip_address, 0)
  }

  provisioner "local-exec" {
    # Bootstrap script called with private_ip of each node in the cluster
    command = "echo ${join(" Cluster local IP is : ", azurerm_public_ip.training.*.ip_address)}"
  }
}
```

The `null_resource` uses the `null` provider, so you need to initialize the configuration to download the `null` provider plugin. Then run a `terraform apply`.

```bash
terraform init
terraform apply
```

### Step 2.2: Re-run `plan` and `apply` to trigger `null_resource`

After the infrastructure has completed its buildout, change your machine count (`num_vms` in your terraform.tfvars) and re-run a plan and apply and notice that the null resource is triggered.  This is because the `web_cluster_size` changed, triggering our null_resource.

```bash
terraform apply
```

If you run `terraform plan` again, the `null_resource` will not be triggered because the `web_cluster_size` value has not changed.

### Step 2.3: Destroy

Finally, run `destroy`.

```bash
terraform destroy
```

## Bonus Task

The `null_resource` is being deprecated in favor of the built-in `terraform_data` resource. Refactor the configuration to use the `terraform_data` resource instead of the `null_resource`.
