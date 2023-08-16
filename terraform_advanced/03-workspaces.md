## Description

In this challenge you will configure your Terraform code to deploy to multiple workspaces.

Duration: 15 minutes

- Task 1: Create the Terraform configuration
- Task 2: Create a development workspace and deploy the configuration
- Task 3: Create and deploy to the staging workspace
- Task 4: Create and deploy to the production workspace
- Task 5: Destroy and delete the staging workspace

## Task 1: Create the Terraform configuration

Start by creating a new directory for the workspaces configuration and creating `main.tf` and `terraform.tf` files.

```bash
mkdir ~/workstation/terraform/workspaces && cd $_
touch {terraform,main}.tf
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
resource "azurerm_resource_group" "workspaces" {
  name     = "${terraform.workspace}-network"
  location = "eastus"

  tags = {
      Environment = terraform.workspace
  }
}

locals {
    vnet_address_space = {
        development = "10.42.0.0/24"
        staging = "10.42.1.0/24"
        production = "10.42.2.0/24"
    }
}

resource "azurerm_virtual_network" "workspaces" {
  resource_group_name = azurerm_resource_group.workspaces.name
  location            = azurerm_resource_group.workspaces.location
  name                = "${terraform.workspace}-network"
  address_space       = [local.vnet_address_space[terraform.workspace]]

  subnet {
    name           = "web"
    address_prefix = local.vnet_address_space[terraform.workspace]
  }

  tags = {
      Environment = terraform.workspace
  }
}
```

Initialize the configuration, but do not apply it.

```bash
terraform init
```

## Task 2: Create a development workspace and deploy the configuration

Create a development workspace for deployment:

```bash
terraform workspace new development
```

You are automatically switched to the new workspace. You can run `terraform console` to see the value of `terraform.workspace`.

Deploy the configuration and note the naming and tags for the resources as well as the IP address range:

```bash
terraform plan
terraform apply
```

Take a look at the directory structure and you'll now see a `terraform.tfstate.d` for the workspaces.

## Task 3: Create and deploy to the staging workspace

Create a staging workspace for deployment and deploy the configuration:

```bash
terraform workspace new staging
terraform apply
```

## Task 4: Create and deploy to the production workspace

Create a production workspace for deployment and deploy the configuration:

```bash
terraform workspace new production
terraform apply
```

Check out all your workspaces!

```bash
terraform workspace list
```

You can also view all the state files in the `terraform.tfstate.d` directory:

```bash
ls -l terraform.tfstate.d/
ls -l terraform.tfstate.d/development/
```

## Task 5: Destroy and delete the staging workspace

Try to delete the staging workspace:

```bash
terraform workspace delete staging
```

Destroy the staging workspace:

```bash
terraform workspace select staging
terraform destroy
```

Now you can delete the workspace:

```bash
terraform workspace select development
terraform workspace delete staging
```
