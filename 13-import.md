# Importing Resources into Terraform From Azure

## Expected Outcome

You will use Terraform import to import a Resource Group into Terraform state and take over management of that Azure Resource Group.

In this challenge, you will:

- Initialize Terraform
- Build a Azure Resource Group in HCL
- Run an `import` to import Azure infrastructure into Terraform State
- Run a `plan` and `apply` to upodate Azure infrastructure
- Run a `destroy` to remove Azure infrastructure

### Import the Resource Group

We need two values to run the `terraform import` command:

1. Resource Address for our configuration
1. Azure Resource ID

The Resource Address can be whatever we would like to reference the resource group as.
For this lab the reference will be "azurerm_resource_group.my_rg".

We first need to simply need to add this into our `main.tf`

```hcl
provider azurerm {
    features {}
}

resource "azurerm_resource_group" "my_rg" {
  name = "my_rg"
  location = "eastus"
}
```

and then initialize terraform:

```sh
terraform init
```

The Azure Resource ID can be retrieved using the Azure CLI by running `az group show -g import-rg-1 --query id`.
The value should look something like "/subscriptions/xxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx/resourceGroups/import-rg-1".

You will be provided the Resource Group ID to import by your instructor.

Now run the import command:

```sh
terraform import azurerm_resource_group.my_rg /subscriptions/xxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx/resourceGroups/import-rg-1

Import successful!
```

The resources that were imported are shown above.
These resources are now in your Terraform state and will henceforth be managed by Terraform.

You can inspect the resource group that was added into state by performing a

```
terraform state show azurerm_resource_group.my_rg
```

```text
$ terraform state show azurerm_resource_group.my_rg
resource "azurerm_resource_group" "my_rg" {
    id       = "/subscriptions/e1f6a3f2-9d19-4e32-bcc3-1ef1517e0fa5/resourceGroups/import-rg-1"
    location = "eastus"
    name     = "import-rg-1"
    tags     = {}

    timeouts {}
}
```

### Verify Plan

Run a `terraform plan`.
You may see see changes if your name or location in the configuration is different from the resource shown in state which it most likely will be.  Update the name attribute of the resource group in the `main.tf` to reflect the name of the resource group that was imported.

```sh
terraform plan
...

No changes. Infrastructure is up-to-date.

This means that Terraform did not detect any differences between your
configuration and real physical resources that exist. As a result, no
actions need to be performed.
```

### Make a Change

Add the following tag configuration to the Resource Group

```hcl
resource "azurerm_resource_group" "import" {
  ...
  tags = {
    terraform = "true"
  }
}
```

Run a plan, we should see two changes.

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

```sh
terraform destroy
```

Because the infrastructure is now managed by Terraform, we can destroy just like before.

Run a `terraform destroy` and follow the prompts to remove the infrastructure.

## Resources

- [Terraform Import](https://www.terraform.io/docs/commands/import.html)
