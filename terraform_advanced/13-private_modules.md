# Terraform Cloud/Enterprise - Private Module Registry

## Expected Outcome

In this challenge you will register some modules with your Private Module Registry then reference them in a workspace.

## How to:

### Fork the Module Repositories

You are going to fork this repository into your GitHub account.

- https://github.com/ned1313/terraform-azurerm-networking

The repository represents a module that can be developed and versioned independently.

### Create a VCS Connection

In Terraform Cloud, navigate to "Settings" -> "Version Control" and click "Add a VCS Provider".

Select `GitHub.com (custom)` as the VCS connection type.

Follow the directions to create an OAuth Application in GitHub.

Once you're created the application in GitHub, copy the client ID to the Terraform Cloud form. And then generate a client secret and copy that to the Terraform Cloud form.

You can set a Name for the application if you want, but it's not required.

Click on Authorize for Terraform Cloud.

### Add Modules

We need to add the repository into the Private Module Registry.

In Terraform Cloud, go into Registry, and click the "Publish" menu and select "Module".

Select the networking repository you forked earlier.

> Note: You will see your github user name instead of 'ned1313/' since you forked this repo.

Click "Publish Module".

This will query the repository for necessary files and tags used for versioning.

Congrats, you are done!

### Create a new github repository to use the module

In github, create a new public repository names "tfc-workspace-modules".

Create a single `main.tf` file with the following contents:

```hcl
variable "name" {}
variable "location" {}

provider "azurerm" {
  features {}
}

variable "vnet_address_spacing" {
  type = list
}

variable "subnet_address_prefixes" {
  type = list
}

module "networking" {
  source  = "app.terraform.io/YOUR_ORG_NAME/networking/azurerm"
  version = "~> 1.0"

  name                    = var.name
  location                = var.location
  vnet_address_spacing    = var.vnet_address_spacing
  subnet_address_prefixes = var.subnet_address_prefixes
}
```

Update the source argument for the networking module to your organization by replacing "YOUR_ORG_NAME" with your TFC organization name.

Commit the file and check the code into github.

### Create a workspace

Create a TFC workspace that uses the VCS connection to load this new repository.

Select the repository and name the workspace the same thing "tfc-workspace-modules"

### Configure Workspace Variables

Fill out the variables for the workspace based on the following list:

Set the Terraform Variables:

- 'name' - A unique environment name such as `###env`
- 'location' - An Azure region such as `eastus` or `centralus`
- 'vnet_address_spacing' (HCL) - The Vnet Address space
    ```hcl
    ["10.0.0.0/16"]
    ```
- 'subnet_address_prefixes' (HCL) - The Subnet Address spaces representing 3 subnets
    ```hcl
    [
    "10.0.0.0/24",
    "10.0.1.0/24",
    "10.0.2.0/24"
    ]
    ```

Click on Save variables.

Do not start a new plan yet, instead click on `Go to workspace overview`.

Set Environment Variables for your Azure Service Principal (be sure check the 'sensitive' checkbox to hide these values).

You can get the current values using the following command from the lab environment:

```bash
env | grep ARM
```

- ARM_TENANT_ID
- ARM_SUBSCRIPTION_ID
- ARM_CLIENT_ID
- ARM_CLIENT_SECRET

### Run a Plan

Click the "Actions" button and select "Start new run".

Select a "Plan and apply" run and click "Start run".

Wait for the Plan to complete.

You should see several additions to deploy your networking.

### Apply the Plan

Approve the plan and apply it.

Watch the apply progress and complete.

Login to the at Azure Portal to see your infrastructure.

## Advanced areas to explore

1. Make a change to a module repository and tag it in such a way that the change shows in your Private Module Registry.

## Clean Up

Navigate to the workspace "Settings" -> "Destruction and Deletion".

Click Queue Destroy Plan

Once the plan completes, apply it to destroy your infrastructure.

## Resources

- [Private Registries](https://www.terraform.io/docs/registry/private.html)
- [Publishing Modules](https://www.terraform.io/docs/registry/modules/publish.html)
