# Azure Virtual Machine

## Expected Outcome

In this challenge, you will create a Azure Virtual Machine and use the `custom_data` argument to provision a simple web app.

You will gradually add Terraform configuration to build all the resources needed to be able to login to the Azure Virtual Machine.

The resources you will use in this challenge:

- Resource Group
- Virtual Network
- Subnet
- Network Interface
- Virtual Machine
- Public IP Address

## How to

### Create the base Terraform Configuration

Change directory into a folder specific to this challenge.

For example: `cd /workstation/terraform/azure/101-custom-data/`.

We will start with a few of the basic resources needed.

Create a `variables.tf`, `main.tf`, `output.tf`, `vm.tf`, `nsg.tf` and `terraform.tfvars` files to hold our configuration.

### Create Variables

Create a few variables that will help keep our code clean in the `variables.tf`

```hcl
variable "prefix" {
  description = "Unique prefix, no dashes or numbers please."
}

variable "location" {}
variable "admin_username" {}
variable "admin_password" {}
```

### Create a Resource Group

Now create a Resource Group to contain all of our infrastructure using the variables to interpolate the parameters in the `main.tf`

```hcl
provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "rg" {
  name     = "${var.prefix}-customdata-rg"
  location = var.location
}
```

### Create Virtual Networking

Create a Virtual Network, Subnet, and Public IP in the `main.tf`

```hcl
resource "azurerm_virtual_network" "vnet" {
  name                = "${var.prefix}TFVnet"
  address_space       = ["10.0.0.0/16"]
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_subnet" "subnet" {
  name                 = "${var.prefix}TFSubnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_public_ip" "publicip" {
  name                = "${var.prefix}publicipcustomdata"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Dynamic"
  domain_name_label   = "${lower(var.prefix)}publicipcustomdata"
}
```

### Create Network Security Group

Create an NSG with two rules, one to allow SSH (22) and another for our web app traffic (8000) in the `nsg.tf`

```hcl
resource "azurerm_network_security_group" "nsg" {
  name                = "${var.prefix}TFNSG"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_network_security_rule" "ssh" {
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.nsg.name
  name                        = "SSH"
  priority                    = 1001
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "22"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
}

resource "azurerm_network_security_rule" "app" {
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.nsg.name
  name                        = "App"
  priority                    = 1002
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "8000"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
}
```

### Create the NIC and VM

Add the networking and VM into the `vm.tf`:

```hcl
resource "azurerm_network_interface" "nic" {
  name                      = "${var.prefix}NIC"
  location                  = var.location
  resource_group_name       = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "${var.prefix}NICConfg"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "dynamic"
    public_ip_address_id          = azurerm_public_ip.publicip.id
  }
}

# Create a Linux virtual machine
resource "azurerm_virtual_machine" "vm" {
  name                  = "${var.prefix}TFVM"
  location              = var.location
  resource_group_name   = azurerm_resource_group.rg.name
  network_interface_ids = [azurerm_network_interface.nic.id]
  vm_size               = "Standard_DS1_v2"

  storage_os_disk {
    name              = "${var.prefix}OsDisk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Premium_LRS"
  }

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  os_profile {
    computer_name  = "${var.prefix}TFVM"
    admin_username = var.admin_username
    admin_password = var.admin_password
    custom_data          = <<-SCRIPT
#!/bin/bash

# Setup logging
logfile="/home/${var.admin_username}/custom-data.log"
exec > $logfile 2>&1

python3 -V
sudo apt update
sudo apt install -y python3-pip python3-flask
python3 -m flask --version

sudo cat << EOF > /home/${var.admin_username}/hello.py
from flask import Flask
import requests

app = Flask(__name__)

import requests
@app.route('/')
def hello_world():
    return """<!DOCTYPE html>
<html>
<head>
    <title>Kittens</title>
</head>
<body>
    <img src="http://placekitten.com/200/300" alt="User Image">
</body>
</html>"""
EOF

chmod +x /home/${var.admin_username}/hello.py

sudo -b FLASK_APP=/home/${var.admin_username}/hello.py flask run --host=0.0.0.0 --port=8000
SCRIPT
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }
}
```

> Note: Carefully look at the `custom_data` argument, especially how there are variable inserts into the script.

### Add an Output

Create an output that will allow for easy navigation to the web app in the `output.tf`

```hcl
output "app-URL" {
  value = "http://${azurerm_public_ip.publicip.fqdn}:8000"
}
```

### Pass in Variables

Create a file called `terraform.tfvars` and add the following variables:

Replace "###" with your initials in quotes.

```sh
prefix   = "###"
location = "East US"
admin_username = "Plankton"
admin_password = "Password1234!"
```

### Run Terraform Workflow

Run `terraform init` since this is the first time we are running Terraform from this directory.

Run `terraform plan` where you should see the plan of all the new resources.

Run `terraform apply` to create all the infrastructure.

After a successful apply, navigate to the listed URL to see the web app.

### Clean up

When you are done, run `terraform destroy` to remove everything we created.

## Advanced areas to explore

1. Convert the inline `custom_data` script to use the [Terraform Template](https://www.terraform.io/docs/providers/template/d/file.html) data resource.
2. Create additional customization of the `custom_data` script to pass in your own "src" image URL.
