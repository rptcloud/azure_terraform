# Lab: Basic Configuration

Duration: 10 minutes

You'll receive login information for your workstation from the instructor. This lab is to verify you can connect to that workstation and can make changes to the base Terraform configuration there.

- Task 1: Create a basic Terraform configuration for an Azure resource group
- Task 3: Initialize & apply the configuration
- Task 4: Change and re-apply the configuration


## Task 1: Create a basic Terraform configuration for an Azure resource group using your workstation and initials as the resource group name

Create a `main.tf` inside the azure working directory and paste the Terraform configuration for an Azure resource group.  Replace the prefix with with your intials.
```
provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "training" {
  name     = "<initials>-resourcegroup"
  location = "East US"
}
```

Turn on auto-save within VS Code if it isn't already enabled.


## Task 2: Initialize and apply your configuration

### 1. Run `terraform init` to download the required providers
### 2. Run `terraform plan` to view the resources that will be created
### 3. Run `terraform apply` to create the resources specified


## Task 3: Edit your Terraform configuration and re-apply

### 1. Edit the main.tf file and add the underlying network infrastructure.

Replace the ### with your initials.

```
resource "azurerm_virtual_network" "training" {
  name                = "azureuser###vn"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.training.location
  resource_group_name = azurerm_resource_group.training.name
}

resource "azurerm_subnet" "training" {
  name                 = "azureuser###sub"
  resource_group_name  = azurerm_resource_group.training.name
  virtual_network_name = azurerm_virtual_network.training.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_public_ip" "training" {
  name                         = "azureuser###ip"
  location                     = azurerm_resource_group.training.location
  resource_group_name          = azurerm_resource_group.training.name
  allocation_method            = "Dynamic"
  idle_timeout_in_minutes      = 30
  domain_name_label = "azureuser###domain"
}

resource "azurerm_network_interface" "training" {
  name                = "azureuser###ni"
  location            = azurerm_resource_group.training.location
  resource_group_name = azurerm_resource_group.training.name

  ip_configuration {
    name                          = "azureuser###ip"
    subnet_id                     = azurerm_subnet.training.id
    private_ip_address_allocation = "static"
    private_ip_address            = "10.0.2.5"
    public_ip_address_id          = azurerm_public_ip.training.id
  }
}
```
### 2. Run `terraform apply` and notice what resources are modified