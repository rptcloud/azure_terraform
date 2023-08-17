# Lab: Terraform Cloud - VCS Code Promotion

GitOps is an operational framework that takes DevOps best practices that we use for application development (Version Control / Collaboration / Compliance / CI/CD) and apply these core concepts to infrastructure automation

- IaC (Infrastructure as Code)
- Merge Requests
- Pipelines

In this challenge, we will utilize the benefits the VCS connected workflow to promote code from a `development` branch into our `main` branch of the `tfc-azure-example` code repository.

Duration: 30 minutes

- Task 1: Clone the `tfc-azure-example` code repository
- Task 2: Create a `web-net-dev` workspace to point to your `development` branch.
- Task 3: Create a `web-net-prod` workspace
- Task 4: Perform and update on your development branch to validate
- Task 5: Merge Change into `main` branch

## Task 1: Clone the `tfc-azure-example` code repository

Fork the following registry into your GitHub account: [tfc-azure-example](https://github.com/ned1313/tfc-azure-example)

In the `tfc-azure-example` github repository, create a `development` branch if one does not already exist.

## Task 2: Create a `web-net-dev` workspace to point to your `development` branch

Create a new TFC workspace named `web-net-dev` that is tied to the `tfc-azure-example` github repo by choosing a VCS Control workflow. In the advanced settings under *VCS Branch*, configure it to watch the development branch.

In the next screen, set the Terraform variable called `prefix` to `dev`, and click on "Save variables".

You are going to use the same Azure credentials for each environment. It's easier to create a variable set that can be shared across workspaces.

Click on `Settings` and then select *Variable sets* from the left side menu.

Create a new variable set called `azure-creds` and make it available to all workspaces. Add four **environment** variables to the variable set:

- ARM_TENANT_ID
- ARM_SUBSCRIPTION_ID
- ARM_CLIENT_ID
- ARM_CLIENT_SECRET

Use the values from your workstation. You can find them by running `env | grep ARM`.

Click on **Create variable set** to complete the process.

Back in the `web-net-dev` workspace, kick off a run and approve it once the plan completes.

## Task 3: Create a `web-net-prod` workspace

Create a new TFC workspace named `web-net-prod` that is tied to the `tfc-azure-example` github repo by choosing a VCS Control workflow. Under Advanced settings, check the box for *Automatic speculative plans*. Leave the rest of the defaults as this will be tracking the default branch of the repo.

In the workspace, add a Terraform variable called `prefix` and set it to `prod`.

Run a plan and approve it to create the base infrastructure for the production environment.

## Task 4: Perform and update on your development branch to validate

On the development branch, add an `owners` tag to the resource group in the `main.tf` file:

```hcl
resource "azurerm_resource_group" "web" {
  name     = local.base_name
  location = var.location
  
  tags = {
    "environment" = var.prefix
    "owner" = "clippy"
  }
}
```

Commit the changes directly to the `development` branch.

This will trigger a Terraform run that is tied to the last commit on your `development` branch. Since there was no change to the infrastructure, there will be no option to approve the plan.

## Task 5: Merge Change into `main` branch

Once the `web-server-dev` TFC workspace completes its run, create a pull request to merge the change into the `main` branch.

The GitOps workflow allows code to be merged into another branch via a pull request. Terraform Cloud's VCS control workflow integrates into this process showing if the deployment into the `web-server-dev` workspace was successful.

This allows the pull request approver to have visibility that the code change was successful in the `development` environment, and view the details of the change within Terraform Cloud.

The pull request will automatically kick off a speculative plan in the `web-server-prod` workspace. You can view the results from the task's **Details** link in the pull request.

Once the speculative plan completes, you can approve the pull request.

When the Merge is approved this will automatically trigger the deployment of the code into the `web-server-prod` workspace. From the workspace, approve the planned changes.

We have successfully now made changes into the development environment and promoted those changes into production via a GitOps workflow.
