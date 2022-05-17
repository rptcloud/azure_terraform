# Lab: Secure Variables

Duration: 15 minutes

You can store your variable values in a Terraform Cloud workspace. In this lab we will create a Terraform configuration that uses your Terraform cloud organization. Then we will provision the workspace to use our Azure credentials and Terraform variable values to provision Azure infrastructure.

## Task 1: Create the Terraform Configuration

Create the directory for the Terraform config:

```bash
mkdir tfc-secure-variables && cd tfc-secure-variables
touch {terraform,main}.tf
```

Populate the Terraform files:

*Update the "YOUR_ORGANIZATION_NAME" value.*

`terraform.tf`

```terraform
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.0"
    }
  }

  backend "remote" {
      organization = "YOUR_ORGANIZATION_NAME"

      workspaces {
          name = "tfc-secure-variables"
      }
  }
}

provider "azurerm" {
  features {}
}
```

`main.tf`

```terraform
variable "prefix" {
  type        = string
  description = "(Required) User initials for naming of resources"
}

variable "location" {
  type = string
  description = "(Optional) Azure region to use, defaults to East US."
  default = "eastus"
}

resource "azurerm_resource_group" "training" {
  name     = "azureuser${var.prefix}tfc"
  location = var.location
}

resource "azurerm_virtual_network" "training" {
  name                = "azureuser${var.prefix}tfc"
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
```

## Task 2: Login to TFC and initialize the configuration

Log into your TFC account:

```bash
terraform login
```

Initialize the Terraform configuration

```bash
terraform init
```

## Task 3: Update the variables in your TFC workspace

Get the current values of the Azure environment variables:

```bash
env | grep ARM
```

Go to the workspace in Terraform Cloud. On the variables tab, add the environment variables for the Azure provider. Be sure to set the `ARM_CLIENT_SECRET` value as sensitive.

Add a Terraform variable value for the `prefix` variable set to your initials.

## Task 4: Perform a run from the CLI using TFC

Kick off a run from the CLI:

```bash
terraform plan
```

Observe that this is a speculative plan.

Kick off an apply from the CLI:

```bash
terraform apply
```

Approve the apply from the Terraform Cloud UI and view the state data when the run completes.

## Task 5: (BONUS) Change the prefix

If you're feeling like a little bonus content, try changing the `prefix` variable value and running a plan directly from the UI.