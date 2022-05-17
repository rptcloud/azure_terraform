# Importing Resources into Terraform From Azure

## Expected Outcome

You will use Terraform import to import a Resource Group into Terraform state and take over management of that Azure Resource Group.

In this challenge, you will:

- Create a Resource Group
- Get the Resource Group ID
- Build a Azure Resource Group in HCL
- Run an `import` to import Azure infrastructure into Terraform State
- Run a `plan` and `apply` to upodate Azure infrastructure
- Run a `destroy` to remove Azure infrastructure

### Create the Resource Group

We are first going to use the Azure portal to create a Resource Group. Take the following steps:

1. From the Azure Portal sign in using the credentials on the *Cloud Portals* tab
1. Create a new resource group called `import-me` in the `East US` region
1. When the resource group has been created, look at the *Properties* section and make note of the *Resource ID*

### Import the Resource Group

We need two values to run the `terraform import` command:

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
```

and then initialize terraform:

```sh
terraform init
```

Now run the import command using the *Resource ID* from the portal:

```sh
terraform import azurerm_resource_group.my_rg /subscriptions/xxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx/resourceGroups/import-me

Import successful!
```

You can inspect the resource group that was added into state by using the `state` command.

```bash
terraform state show azurerm_resource_group.my_rg
```

```text
$ terraform state show azurerm_resource_group.my_rg
# azurerm_resource_group.my_rg:
resource "azurerm_resource_group" "my_rg" {
    id       = "/subscriptions/0956ce2e-e325-4642-9071-b8deae2c8ab3/resourceGroups/import-me"
    location = "eastus"
    name     = "import-me"
    tags     = {}

    timeouts {}
}
```

### Verify Plan

Run a `terraform plan`.
You may see see changes if your name or location in the configuration is different from the resource shown in state.  Update the name attribute of the resource group in the `main.tf` to reflect the name of the resource group that was imported if it is different.

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
resource "azurerm_resource_group" "my_rg" {
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
- [Aztfy](https://github.com/Azure/aztfy)