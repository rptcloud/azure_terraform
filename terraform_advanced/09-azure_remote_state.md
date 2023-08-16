# Lab: Azure Remote State

## Description

In this challenge you will use create an Azure storage account for remote state storage and then update a configuration to use that storage account.

You can store your state data in one of several remote locations. In this challenge you will deploy a configuration using the `local` state backend, and then migrate the state data to the `azurerm` backend.

Duration: 15 minutes

- Task 1: Create the the storage account and backend configuration
- Task 2: Deploy the configuration using the `local` backend
- Task 3: Update the configuration with the `azurerm` backend and migrate your state data

## Task 1: Create the the storage account and backend configuration

You will use Terraform to create the Azure storage account, a container in the storage account, and a SAS token with permissions to access the storage account. The resulting configuration will be written out to a `backend.txt` file you can use with the main configuration.

Create the folder structure for the storage account and main configuration:

```bash
mkdir -p ~/workstation/terraform/azure_remote_state/{storage_account,vnet}
touch ~/workstation/terraform/azure_remote_state/storage_account/{terraform,main}.tf
touch ~/workstation/terraform/azure_remote_state/vnet/{terraform,main}.tf
touch ~/workstation/terraform/azure_remote_state/storage_account/terraform.tfvars
cd ~/workstation/terraform/azure_remote_state/storage_account
```

First you need to deploy the storage account.

Add the following to the `terraform.tf` file in the `storage_account` directory:

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

Add the following to the `main.tf` file in the `storage_account` directory:

```hcl
### AZURE VARIABLES ###

# Azure region for deployment
variable "azure_region" {
  type    = string
  default = "eastus"
}

# Naming prefix
variable "prefix" {
  type        = string
  description = "Naming prefix for resources"
  default     = "eco"
}

# Tags for resources

variable "common_tags" {
  type        = map(string)
  description = "Map of tags to apply to all resources"
}

# Local values for resource group and storage account
resource "random_integer" "suffix" {
  min = 10000
  max = 99999
}

locals {
  az_resource_group_name  = "${var.prefix}${random_integer.suffix.result}"
  az_storage_account_name = "${lower(var.prefix)}${random_integer.suffix.result}"
}

# Resource group
resource "azurerm_resource_group" "setup" {
  name     = local.az_resource_group_name
  location = var.azure_region

  tags = var.common_tags
}

# Storage account
resource "azurerm_storage_account" "sa" {
  name                     = local.az_storage_account_name
  resource_group_name      = azurerm_resource_group.setup.name
  location                 = azurerm_resource_group.setup.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  tags = var.common_tags

}

# Storage container
resource "azurerm_storage_container" "ct" {
  name                 = "terraform-state"
  storage_account_name = azurerm_storage_account.sa.name

}

# SAS Token data source
data "azurerm_storage_account_sas" "state" {
  connection_string = azurerm_storage_account.sa.primary_connection_string
  https_only        = true

  resource_types {
    service   = true
    container = true
    object    = true
  }

  services {
    blob  = true
    queue = false
    table = false
    file  = false
  }

  start  = timestamp()
  expiry = timeadd(timestamp(), "2160h")

  permissions {
    read    = true
    write   = true
    delete  = true
    list    = true
    add     = true
    create  = true
    update  = false
    process = false
    filter  = false
    tag     = false
  }
}

# Init string
output "init_string" {
  value = <<INIT
-backend-config=storage_account_name=${azurerm_storage_account.sa.name} -backend-config=container_name=${azurerm_storage_container.ct.name} -backend-config=sas_token="${nonsensitive(data.azurerm_storage_account_sas.state.sas)}"
INIT
}
```

Add the following to the `terraform.tfvars` file and update the `###` to your initials:

```hcl
# AZURE VALUES
azure_region = "eastus"

prefix = "###"

common_tags = {
  Business-Unit = "WebDev-NA"
  Project-ID    = "WebApp-101"
  Cost-Center   = "AppDev-NA"
}
```

Finally, deploy the configuration and make note of the output. You'll use the `init_string` along with `terraform init` to migrate to the `azurerm` backend.

```bash
terraform init
terraform apply
```

## Task 2: Deploy the configuration using the `local` backend

In the `vnet` directory add the following to the `terraform.tf` directory:

```hcl
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.0"
    }
  }

  #backend "azurerm" {
  #  key = "terraform.tfstate"
  #}
}

provider "azurerm" {
  features {}
}
```

And add the following to the `main.tf` file:

```hcl
resource "azurerm_resource_group" "remote_state" {
  name     = "move-network"
  location = "eastus"

}

resource "azurerm_virtual_network" "remote_state" {
  resource_group_name = azurerm_resource_group.remote_state.name
  location            = azurerm_resource_group.remote_state.location
  name                = "move-network"
  address_space       = ["10.0.0.0/24"]

  subnet {
    name           = "web"
    address_prefix = "10.0.0.0/24"
  }
}
```

At first you are going to use the `local` backend, so the `azurerm` backend is commented out. You'll remove those comments in a moment. For now, initialize and apply the configuration:

```bash
cd ../vnet/
terraform init
terraform apply
```

## Task 3: Update the configuration with the `azurerm` backend and migrate your state data

You are going to migrate your existing state data to the Azure storage account created earlier. Start by removing the comment `#` squares from the `backend` block:

```hcl
  backend "azurerm" {
    key = "terraform.tfstate"
  }
```

You are changing the backend for state data, so Terraform must be initialized with the new values. The `backend` block is a partial configuration. The rest of the configuration will be specified as part of the `terraform init` command. You will need that `init_string` output now to run the command.

```bash
terraform -chdir="../storage_account" output init_string
```

Do not copy the `<<EOT` and `EOT` lines. Only copy the string between them. It should look something like this:

```bash
-backend-config=storage_account_name=eco98775 -backend-config=container_name=terraform-state -backend-config=sas_token="?sv=2017-07-29&ss=b&srt=sco&sp=rwdlac&se=2022-08-16T15:51:29Z&st=2022-05-18T15:51:29Z&spr=https&sig=45%2B3sGaBL%2F6Pw4YEDQG70kbKu%2FDojFlWILlyqz43mQA%3D"
```

Copy the string and paste it into the `terraform init` command.

```bash
terraform init PASTE_THE_STRING_HERE
```

Your command and the output should look something like this:

```console
terraform init -backend-config=storage_account_name=eco98775 -backend-config=container_name=terraform-state -backend-config=sas_token="?sv=2017-07-29&ss=b&srt=sco&sp=rwdlac&se=2022-08-16T15:51:29Z&st=2022-05-18T15:51:29Z&spr=https&sig=45%2B3sGaBL%2F6Pw4YEDQG70kbKu%2FDojFlWILlyqz43mQA%3D"

Initializing the backend...
Do you want to copy existing state to the new backend?
  Pre-existing state was found while migrating the previous "local" backend to the
  newly configured "azurerm" backend. No existing state was found in the newly
  configured "azurerm" backend. Do you want to copy this state to the new "azurerm"
  backend? Enter "yes" to copy and "no" to start with an empty state.

  Enter a value: yes


Successfully configured the backend "azurerm"! Terraform will automatically
use this backend unless the backend configuration changes.
```

The local `terraform.tfstate` is now empty:

```bash
cat terraform.tfstate
```

You can now delete the local `terraform.tfstate` file and run a `terraform plan` to confirm the state data migration was successful.

The new backend configuration is held in the `.terraform/terraform.tfstate` file. You can view the contents of that file to see the new configuration:

```bash
cat .terraform/terraform.tfstate
```

```bash
{
    "version": 3,
    "serial": 1,
    "lineage": "b803be3b-bf51-0f78-858c-bd4b0e7b928d",
    "backend": {
        "type": "azurerm",
        "config": {
            "access_key": null,
            "client_certificate_password": null,
            "client_certificate_path": null,
            "client_id": null,
            "client_secret": null,
            "container_name": "terraform-state",
            "endpoint": null,
            "environment": null,
            "key": "terraform.tfstate",
...
```
