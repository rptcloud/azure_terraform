## Description

In this challenge you will use conditional logic to decide whether to create an Application Gateway subnet in a network module.

Duration: 15 minutes

- Task 1: Create the network module
- Task 2: Use the network module in your root module
- Task 3: Deploy the configuration with conditional logic

## Task 1: Create the network module

The root module is going to use a network module to create an Azure Virtual Network with an optional Application Gateway subnet. The Application Gateway will use the first /24 of the IP Address space assigned to the Virtual Network.

Create the folder structure for the root module and network module:

```bash
mkdir -p ~/workstation/terraform/conditional_logic/network && cd $_
touch {terraform,main,variables}.tf
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

Since this is a module, you should not define a provider. That will come from the root module.

Add the following to the `variables.tf` file:

```hcl
variable "vnet_address_prefix" {
  type        = string
  description = "(Required) The address prefix to use for the virtual network."
}

variable "naming_prefix" {
  type        = string
  description = "(Required) Naming prefix for the virtual network. It should be three characters in length."
}

variable "location" {
  type        = string
  description = "(Required) Azure region to use for the virtual network."
}

variable "create_app_gateway_subnet" {
  type        = bool
  description = "(Optional) Whether an app gateway subnet should be created. Defaults to false."
  default     = false
}

variable "app_gateway_subnet" {
  type        = string
  description = "(Optional) Specify the subnet address prefix if the app gateway should be created."
  default     = null
}
```

The creation of the app gateway subnet is conditional on the `create_app_gateway_subnet` variable. We will enact that logic in the `main.tf` file.

Add the following to the `main.tf`:

```hcl
locals {
  base_name = "${var.naming_prefix}vnet"
}

resource "azurerm_resource_group" "net" {
  name     = local.base_name
  location = var.location
}

resource "azurerm_virtual_network" "net" {
  name                = local.base_name
  location            = azurerm_resource_group.net.location
  resource_group_name = azurerm_resource_group.net.name

  address_space = [var.vnet_address_prefix]
}

resource "azurerm_subnet" "app_gateway" {
  count                = var.create_app_gateway_subnet ? 1 : 0
  name                 = "AppGateway"
  resource_group_name  = azurerm_resource_group.net.name
  virtual_network_name = azurerm_virtual_network.net.name

  address_prefixes = [var.app_gateway_subnet]

}
```

By using the count meta-argument, we can set the count to 0 if we don't want it to be created.

## Task 2: Use the network module in your root module

You can now use the network module in your root module. First create the files for the root module:

```bash
cd ..
touch {main,terraform}.tf
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

provider "azurerm" {
  features {}
}
```

Add the following to the `main.tf` file:

```hcl
module "virtual_network_nogw" {
  source = "./network"

  vnet_address_prefix       = "10.0.0.0/16"
  naming_prefix             = "nogw"
  location                  = "eastus"
  create_app_gateway_subnet = false
}

module "virtual_network_withgw" {
  source = "./network"

  vnet_address_prefix       = "10.0.0.0/16"
  naming_prefix             = "appgw"
  location                  = "eastus"
  create_app_gateway_subnet = true
  app_gateway_subnet        = "10.0.0.0/24"
}
```

## Task 3: Deploy the configuration with conditional logic

Initialize the root module and run a plan to observe what will be created:

```bash
terraform init
terraform plan
```

Optionally, you can deploy the configuration as well:

```bash
terraform apply
```
