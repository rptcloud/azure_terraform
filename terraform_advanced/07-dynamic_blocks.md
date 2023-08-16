## Description

In this challenge you will use dynamic blocks to configure network security group rules.

You can define network security group rules in-line within an NSG or as separate resources. In this example we will choose to define them in-line with dynamic blocks.

Duration: 15 minutes

- Task 1: Create the configuration
- Task 2: Test the configuration

## Task 1: Create the configuration

Create the folder structure for the nsg configuration:

```bash
mkdir -p ~/workstation/terraform/nsg_rules && cd $_
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
resource "azurerm_resource_group" "nsg" {
  name     = "nsg-rules-dynamic"
  location = "eastus"
}

locals {
  # Define a local value for the nsg rules
  inbound_nsg_rules = {
    http = {
      priority               = 100
      protocol               = "Tcp"
      destination_port_range = "80"
    }

    https = {
      priority               = 110
      protocol               = "Tcp"
      destination_port_range = "443"
    }

    icmp = {
      priority               = 120
      protocol               = "Icmp"
      destination_port_range = "*"
    }
  }
}

resource "azurerm_network_security_group" "nsg" {
  name                = "web-rules"
  resource_group_name = azurerm_resource_group.nsg.name
  location            = azurerm_resource_group.nsg.location

  dynamic "security_rule" {
    for_each = local.inbound_nsg_rules
    content {
      name                       = security_rule.key
      priority                   = security_rule.value["priority"]
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = security_rule.value["protocol"]
      source_port_range          = "*"
      destination_port_range     = security_rule.value["destination_port_range"]
      source_address_prefix      = "*"
      destination_address_prefix = "*"
    }
  }
}
```

For the rules, we are not defining every value for the rule, just the differences for each rule we want to create.

## Task 2: Test the configuration

Initialize and deploy the configuration:

```bash
terraform init
terraform apply
```

Take a look at the properties of the network security group to validate all the rules have been created.

```bash
terraform state show azurerm_network_security_group.nsg
```

## Bonus Task

How could you handle rules that have different properties defined? Could you use a default value if none is defined by the local value? *Hint: the [lookup](https://www.terraform.io/docs/language/functions/lookup.html) function may be helpful.*
