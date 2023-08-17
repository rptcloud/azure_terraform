# Lab: Migrating State to Terraform Cloud

In this lab you will create and deploy an Azure Virtual Network using Terraform, and then migrate the state data to Terraform Cloud. We will continue to use this configuration in the next lab.

Duration: 10 minutes

- Task 1: Create an Azure Virtual Network
- Task 2: Migrate State to Terraform Cloud

## Task 1: Create the Terraform Configuration

Create the directory for the Terraform config:

```bash
mkdir -p ~/workstation/terraform/azure/tfc-azure-vnet && cd $_
touch {terraform,main}.tf
touch terraform.tfvars
```

Populate the Terraform files:

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

`terraform.tfvars`

```terraform
prefix = "###" # Replace with your initials
```

Deploy the configuration:

```bash
terraform init
terraform apply
```

## Task 2: Migrate State to Terraform Cloud

Now that you have the infrastructure deployed, add the following `cloud` block to the `terraform` block in `terraform.tf`, changing the `organization` value to your organization name:

```terraform
  cloud {
      organization = "YOUR_ORGANIZATION_NAME"

      workspaces {
          name = "tfc-azure-vnet"
      }
  }

```

Log into your TFC account (this is only necessary once per sandbox, you can skip this step if you've already logged into Terraform Cloud):

```bash
terraform login
```

Then run `terraform init` again to migrate the state to Terraform Cloud:

```bash
terraform init
```

```bash
Initializing Terraform Cloud...
Do you wish to proceed?
  As part of migrating to Terraform Cloud, Terraform can optionally copy your
  current workspace state to the configured Terraform Cloud workspace.
  
  Answer "yes" to copy the latest state snapshot to the configured
  Terraform Cloud workspace.
  
  Answer "no" to ignore the existing state and just activate the configured
  Terraform Cloud workspace with its existing state, if any.
  
  Should Terraform migrate your existing state?

  Enter a value:
```

You will be prompted to confirm the migration, type `yes` and press enter.

```bash
Initializing provider plugins...
- Reusing previous version of hashicorp/azurerm from the dependency lock file
- Using previously-installed hashicorp/azurerm v3.69.0

Terraform Cloud has been successfully initialized!

You may now begin working with Terraform Cloud. Try running "terraform plan" to
see any changes that are required for your infrastructure.

If you ever set or change modules or Terraform Settings, run "terraform init"
again to reinitialize your working directory.
```

Congratulations, you've successfully migrated your state data to Terraform Cloud!