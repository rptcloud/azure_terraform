# Azure Virtual Machine Scale Set

## Expected Outcome

In this challenge, you will create a Azure Virtual Machine Scale Set.

The resources you will use in this challenge:

- Resource Group
- Virtual Network
- Subnet
- Network Interface
- Virtual Machine Scale Set
- Load Balancer
- Public IP Address

## How to

### Create the base Terraform Configuration

Change directory into a folder specific to this challenge.

For example: `cd /workstation/terraform/azure/virtual-machine-scale-set/`.

We will start with a few of the basic resources needed.

Create a `main.tf` file to hold our configuration.

### Create Variables

Create a file `variables.tf` and add the following configuration:

```hcl
variable "prefix" {}

variable "location" {}

variable "username" {}

variable "vmss_count" {}
variable "address_space" {}

variable "address_prefix" {}
```

### Create Variables TF File

Create a file `terraform.tfvars` and add the following configuration:

```hcl
prefix     = "###"
location   = "East US"
username   = "someadmin"
vmss_count = 1
```

### Create Core Infrastructure

Create a file `core.tf` and add the following configuration:

```hcl
resource "azurerm_resource_group" "main" {
  name     = "${var.prefix}-rg"
  location = var.location
}

resource "azurerm_virtual_network" "main" {
  name                = "${var.prefix}-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
}

resource "azurerm_subnet" "main" {
  name                 = "${var.prefix}-subnet"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.1.0/24"]
}
```

### Create VMSS

Create a file `vmss.tf` and add the following configuration:

```hcl
resource "tls_private_key" "main" {
  algorithm = "RSA"
}

resource "azurerm_virtual_machine_scale_set" "main" {
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  name                = "${var.prefix}-vmss"
  upgrade_policy_mode = "Manual"

  sku {
    name     = "Standard_F2"
    tier     = "Standard"
    capacity = var.vmss_count
  }

  storage_profile_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  storage_profile_os_disk {
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name_prefix = "${var.prefix}vm"
    admin_username       = var.username
  }

  os_profile_linux_config {
    disable_password_authentication = true

    ssh_keys {
      path     = "/home/${var.username}/.ssh/authorized_keys"
      key_data = tls_private_key.main.public_key_openssh
    }
  }
  network_profile {
    name    = "NetworkProfile"
    primary = true

    ip_configuration {
      name                                   = "IPConfiguration"
      primary                                = true
      subnet_id                              = azurerm_subnet.main.id
      load_balancer_backend_address_pool_ids = [azurerm_lb_backend_address_pool.bpepool.id]
      # Uncomment to create a public IP for each instance
      # public_ip_address_configuration {
      #   name              = "${var.prefix}vmsspubip"
      #   idle_timeout      = 4
      #   domain_name_label = "${var.prefix}vmsspubip"
      # }
    }
  }
}
```

### Create Load Balancer

Create a file `lb.tf` and add the following configuration:

```hcl
resource "azurerm_public_ip" "main" {
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  name                = "${var.prefix}-pubip"
  allocation_method   = "Static"
}

resource "azurerm_lb" "main" {
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  name                = "${var.prefix}-lb"

  frontend_ip_configuration {
    name                 = "PublicIPAddress"
    public_ip_address_id = azurerm_public_ip.main.id
  }
}

resource "azurerm_lb_backend_address_pool" "bpepool" {
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  loadbalancer_id     = azurerm_lb.main.id
  name                = "BackEndAddressPool"
}

resource "azurerm_lb_rule" "lb-app" {
  resource_group_name            = azurerm_resource_group.main.name
  loadbalancer_id                = azurerm_lb.main.id
  backend_address_pool_id        = azurerm_lb_backend_address_pool.bpepool.id
  probe_id                       = azurerm_lb_probe.http.id
  name                           = "AppRule"
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  frontend_ip_configuration_name = "PublicIPAddress"
}

resource "azurerm_lb_probe" "http" {
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  loadbalancer_id     = azurerm_lb.main.id
  name                = "ptfe-app-http-probe"
  protocol            = "Http"
  request_path        = "/_health_check"
  port                = 80
}
```

### Run Terraform Workflow

Run `terraform init` since this is the first time we are running Terraform from this directory.

Run `terraform plan` and validate all resources are being created as desired.

Run `terraform apply` and type `yes` when prompted.

Inspect the infrastructure in the portal.

Change the VMSS count to another number and replan, does it match your expectations?

## Advanced areas to explore

1. Add the `custom_data` script from the previous lab to execute within the VM Scale Set. What changes would you have to make?

### Clean up

When you are done, run `terraform destroy` to remove everything we created.