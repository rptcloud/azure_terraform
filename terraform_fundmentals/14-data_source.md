# Lab: Data source

Duration: 15 minutes

You can reference an existing object in Azure by using a data source. This could be an existing resource group, virtual network, or custom image for a virtual machine. In this lab we will create a virtual network and subnet in one configuration and then reference that subnet in as a data source in a separate configuration for an Azure VM.

## Task 1: Create a resource group and virtual network

Create directories for the Virtual Network and Azure VM:

```bash
mkdir -p datasource/{virtual_network,azure_vm}
```

Add the necessary files for the Virtual Network:

```bash
touch datasource/virtual_network/{main,terraform}.tf
```

Populate the files for the virtual network:

`terraform.tf`

```terraform
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.0"
    }
  }
}

provider "azurerm" {
  features {}
}
```

`main.tf`

```terraform
resource "azurerm_resource_group" "data_source" {
  name     = "data-source-network"
  location = "eastus"
}

resource "azurerm_virtual_network" "data_source" {
  resource_group_name = azurerm_resource_group.data_source.name
  location            = azurerm_resource_group.data_source.location
  name                = "data-source-network"
  address_space       = ["10.42.1.0/24"]

  subnet {
    name           = "web"
    address_prefix = "10.42.1.0/24"
  }
}
```

Initialize and deploy the Azure infrastructure:

```bash
cd datasource/virtual_network
terraform init
terraform apply
```

## Task 2: Create a configuration to use the data source

Create the necessary files in the `azure_vm` directory:

```bash
cd ../azure_vm
touch {main,terraform,data}.tf
```

Populate the `terraform.tf` file:

```terraform
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.0"
    }
  }
}

provider "azurerm" {
  features {}
}
```

Populate the `data.tf` file:

```terraform
data "azurerm_subnet" "web_subnet" {
  name                 = "web"
  virtual_network_name = "data-source-network"
  resource_group_name  = "data-source-network"
}

output "web_subnet_id" {
  value = data.azurerm_subnet.web_subnet.id
}
```

Initialize and apply the current config to load the data source:

```bash
terraform init
terraform apply
```

## Task 3: Use the data source for an Azure VM

Populate the `main.tf` file:

```terraform
resource "azurerm_network_interface" "web" {
  name                = "web-nic"
  location            = "eastus"
  resource_group_name = data.azurerm_subnet.web_subnet.resource_group_name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = data.azurerm_subnet.web_subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_linux_virtual_machine" "web" {
  name                = "web-machine"
  resource_group_name = data.azurerm_subnet.web_subnet.resource_group_name
  location            = "eastus"
  size                = "Standard_D2s_v4"
  admin_username      = "adminuser"
  network_interface_ids = [
    azurerm_network_interface.web.id,
  ]

  admin_password = "P@ssw0rd123!"
  disable_password_authentication = false

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }
}
```

Apply the updated configuration:

```bash
terraform apply
```
