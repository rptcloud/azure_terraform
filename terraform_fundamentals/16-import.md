# Importing Resources into Terraform From Azure

## Expected Outcome

You will use Terraform import to import a Resource Group into Terraform state and take over management of that Azure Resource Group.

In this challenge, you will:

- Create a Resource Group
- Get the Resource Group ID
- Build a Azure Resource Group in HCL
- Add an import block to the configuration
- Run a `plan` and `apply` to update Azure infrastructure
- Run a `destroy` to remove Azure infrastructure

### Create the Resource Group

We are first going to use the Azure portal to create a Resource Group. Take the following steps:

1. From the Azure Portal sign in using the credentials on the *Cloud Portals* tab
1. Create a new resource group called `import-me` in the `East US` region
1. When the resource group has been created, look at the *Properties* section and make note of the *Resource ID*

### Import the Resource Group

We need two values for the `import` block:

1. Resource Address for our configuration
1. Azure Resource ID

The Resource Address can be whatever we would like to reference the resource group as within Terraform.
For this lab the reference will be "azurerm_resource_group.my_rg".

We first need to simply need to add this into our `main.tf`

Create a directory called `import_lab` and the `main.tf` file:

```bash
mkdir ~/workstation/terraform/import_lab && cd $_
touch main.tf
```

Add the following into the `main.tf` file:

```hcl
provider azurerm {
    features {}
}

resource "azurerm_resource_group" "my_rg" {
  name = "import-me"
  location = "eastus"
}

import {
  id = "ID GOES HERE"
  to = azurerm_resource_group.my_rg
}
```

and then initialize terraform:

```bash
terraform init
```

Now run the plan command and view the results:

```bash
terraform plan
```

```text
Terraform will perform the following actions:

  # azurerm_resource_group.my_rg will be imported
    resource "azurerm_resource_group" "my_rg" {
        id       = "/subscriptions/16f1299e-c5d6-4d0a-8c74-35852359c75b/resourceGroups/import-me"
        location = "eastus"
        name     = "import-me"
        tags     = {}
    }

Plan: 1 to import, 0 to add, 0 to change, 0 to destroy.
```

If anything is different between the resource in Azure and the resource in the configuration, Terraform will show you the difference as a change.

### Apply the Import

Run a `terraform apply`.

```bash
terraform apply -auto-approve
...
Apply complete! Resources: 1 imported, 0 added, 0 changed, 0 destroyed.
```

You have successfully imported the resource group into Terraform. You can now remove the `import` block from the configuration.

### Make a Change

Add the following tag configuration to the Resource Group

```hcl
resource "azurerm_resource_group" "my_rg" {
  ...
  tags = {
    terraform = "true"
  }
}
```

Run a plan, we should see one change.

```text
 ~ tags     = {
          + "terraform" = "true"
        }

Plan: 0 to add, 1 to change, 0 to destroy.
```

Run `terraform apply`.

SUCCESS! You have now brought existing infrastructure into Terraform.

### Cleanup

When you are done, destroy the infrastructure, you no longer need it.

```bash
terraform destroy
```

Because the infrastructure is now managed by Terraform, we can destroy just like before.

Run a `terraform destroy` and follow the prompts to remove the infrastructure.

## Resources

- [Import Block](https://developer.hashicorp.com/terraform/language/import)
- [Terraform Import](https://www.terraform.io/docs/commands/import.html)
- [Aztfy](https://github.com/Azure/aztfy)