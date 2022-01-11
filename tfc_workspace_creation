# Lab: Automate TFC/TFE Workspace Creation

We can Provision Terraform Cloud or Terraform Enterprise - with Terraform! The Terraform provider allows for the management of organizations, workspaces, teams, variables, run triggers, policy sets, and more.

Duration: 15 minutes

- Task 1: Read information from TFC/TFE with the Terraform tfe provider
- Task 2: Create a TFC/TFE Workspace using the tfe provider
- Task 3: Set Variables within a TFE Workspace
- Task 4: Update the Terraform Version of a Workspace
- Task 5: Automate Team Access across Workspaces

## Task 1: Read information from TFC/TFE with the Terraform tfe provider

Create a new directory for the lab and add the following `main.tf`.

```shell
mkdir -p /workstation/terraform/workspace_automation && cd $_
touch main.tf
```

`main.tf`

```hcl
provider "tfe" {
}

variable "workspace_name" {
  type = string
}

variable "organization" {
  type = string
}

data "tfe_workspace" "workspace" {
  name         = var.workspace_name
  organization = var.organization
}

output "workspace_id" {
  value = data.tfe_workspace.workspace.id
}

output "workspace_terraform_version" {
  value = data.tfe_workspace.workspace.terraform_version
}
```

​
Export a TFC api token as `export TFE_TOKEN=<TOKEN-VALUE>` so that this terraform configuration can authenticate into the TFC Organization.

> Note: TFC User Tokens can be generated within Terraform Cloud > User Settings > Tokens.
> ​
> Run a `terraform init`, `terraform apply`
> ​
> Enter your existing organization and existing workspace to utilize the data blocks
> ​

```bash
terraform init
terraform apply -var "organization=YOUR-ORG" -var "workspace_name=webserver-aws-dev"
```

​

```bash
Apply complete! Resources: 0 added, 0 changed, 0 destroyed.
​
Outputs:
​
workspace_id = "ws-gDZHtb4ibnm6cMTs"
workspace_terraform_version = "0.15.0"
```

​
You can query TFC workspace information for items outlined within the data resource that is stored in the Terraform state file.
​

```bash
terraform state list
​
data.tfe_workspace.workspace
```

​

```bash
terraform state show data.tfe_workspace.workspace
​
# data.tfe_workspace.workspace:
data "tfe_workspace" "workspace" {
    allow_destroy_plan        = true
    auto_apply                = false
    file_triggers_enabled     = false
    global_remote_state       = false
    id                        = "ws-gDZHtb4ibnm6cMTs"
    name                      = "server-build-sandbox"
    operations                = true
    organization              = "RPTData"
    policy_check_failures     = 0
    queue_all_runs            = false
    remote_state_consumer_ids = [
        "ws-1RmFgbYSMYro8zhN",
        "ws-yAipF8Ht6EKMWUgv",
    ]
    resource_count            = 10
    run_failures              = 2
    runs_count                = 4
    speculative_enabled       = false
    terraform_version         = "0.15.0"
    trigger_prefixes          = []
    vcs_repo                  = []
}
```

​
​

## Task 2: Create a TFC/TFE Workspace using the tfe provider

Workspaces are how Terraform Cloud organizes infrastructure. Let's create one with Terraform by updating our `main.tf` file.
​
​

```bash
provider "tfe" {}

variable "workspace_name" {
  type = string
}

variable "workspace_name_new" {
  type = string
}

variable "organization" {
  type = string
}

data "tfe_workspace" "workspace" {
  name         = var.workspace_name
  organization = var.organization
}

resource "tfe_workspace" "workspace_new" {
  name         = var.workspace_name_new
  organization = var.organization
}

output "workspace_id" {
  value = data.tfe_workspace.workspace.id
}

output "workspace_terraform_version" {
  value = data.tfe_workspace.workspace.terraform_version
}

output "workspace_new_id" {
  value = tfe_workspace.workspace_new.id
}

output "workspace_new_terraform_version" {
  value = tfe_workspace.workspace_new.terraform_version
}
```

​

```bash
terraform apply terraform apply -var "organization=YOUR-ORG" -var "workspace_name=webserver-aws-dev"
​
var.workspace_name_new
  Enter a value: webserver-aws-stage # Create a Stage Workspace Name
```

​

```bash
Apply complete! Resources: 1 added, 0 changed, 0 destroyed.
​
Outputs:
​
workspace_id = "ws-gDZHtb4ibnm6cMTs"
workspace_new_id = "ws-nh6ojGDntKv9rtqV"
workspace_new_terraform_version = "1.0.4"
workspace_terraform_version = "0.15.0"
```

​
Validate the new stage workspace has been created within your TFC Organization. Notice that the new workspace defaults to the latest Terraform Core version that is available.

![Terraform Workspace Variables](img/automated_workspace.png)
​
​

## Task 3: Set Variables within a TFE Workspace

Update the `main.tf` to now add Variables to your newly provisioned TFC Workspace
​

```hcl
resource "tfe_variable" "managed" {
  key          = "variable_name"
  value        = "variable_value"
  category     = "terraform"
  workspace_id = tfe_workspace.workspace_new.id
  description  = "This an example of a regular variable"
}

resource "tfe_variable" "sensitive" {
  key          = "my_variable_sensitive"
  value        = "my_sensitive_value"
  category     = "terraform"
  workspace_id = tfe_workspace.workspace_new.id
  description  = "This an example of an sensitive variable"
  sensitive    = true
}

resource "tfe_variable" "hcl" {
  key          = "my_variable_hcl"
  value        = "[hcl_variable_value]"
  category     = "terraform"
  workspace_id = tfe_workspace.workspace_new.id
  hcl          = true
  description  = "This an example of an hcl variable"
}
```

​
Run a `terraform apply`
​

```bash
terraform apply terraform apply -var "organization=YOUR-ORG" -var "workspace_name=webserver-aws-dev"

var.workspace_name_new
  Enter a value: webserver-aws-stage # Replace with your Stage Workspace Name
```

​
Validate that the variables were added to your Workspace
​
![Terraform Workspace Variables](img/tfe_variables.png)
​

## Task 4: Update the Terraform Version of a Workspace

We can also leverage the tfe provider to make update to our workspaces, like changing the Terraform version of our workspace.
​
Update the new tfe_workspace to specify a Terraform version

```hcl
variable "tf_version_stage" {
   default = "1.0.0"
}
resource "tfe_workspace" "workspace_new" {
  name         = var.workspace_name_new
  organization = var.organization
  terraform_version = var.tf_version_stage
}
```

​
Run a `terraform apply`
​

```bash
terraform apply terraform apply -var "organization=YOUR-ORG" -var "workspace_name=webserver-aws-dev"
​
var.workspace_name_new
  Enter a value: webserver-aws-stage # Replace with your Stage Workspace Name
```

​

```bash
Terraform used the selected providers to generate the following execution plan. Resource actions are indicated with the
following symbols:
  ~ update in-place
​
Terraform will perform the following actions:
​
  # tfe_workspace.workspace_new will be updated in-place
  ~ resource "tfe_workspace" "workspace_new" {
        id                        = "ws-nh6ojGDntKv9rtqV"
        name                      = "server-build-prod"
      ~ terraform_version         = "1.0.4" -> "1.0.0"
        # (11 unchanged attributes hidden)
    }
​
Plan: 0 to add, 1 to change, 0 to destroy.
​
Changes to Outputs:
  ~ workspace_new_terraform_version = "1.0.4" -> "1.0.0"
​
Do you want to perform these actions?
  Terraform will perform the actions described above.
  Only 'yes' will be accepted to approve.
​
  Enter a value:
```

​

```bash
Apply complete! Resources: 0 added, 1 changed, 0 destroyed.
​
Outputs:
​
workspace_id = "ws-gDZHtb4ibnm6cMTs"
workspace_new_id = "ws-nh6ojGDntKv9rtqV"
workspace_new_terraform_version = "1.0.0"
workspace_terraform_version = "0.15.0"
```

​
Validate the update terraform version of your workspace.
​

## Task 5: Automate Creation of Production, Development and QA Workspaces

​
Often times we wish to break out our Terraform configuations by the environment with which they reside. Let's showcase how we can use a dynamic block to automate the build out of our Terraform workspace environments. Create an `env.tf`

`env.tf`

```hcl
variable "apps" {
  description = "Map of applications"
  type        = map(any)
  default = {
    appA = {
      terraform_version = "0.15.0"
    },
    appB = {
      terraform_version = "1.0.0"
    }
  }
}

variable "environments" {
  type    = list(any)
  default = ["sandbox", "development", "production"]
}

locals {
  app_env = flatten([for app_key, app in var.apps : [
    for environment in var.environments : {
      app               = app_key
      environment       = environment
      terraform_version = app.terraform_version
    }
    ]
  ])
}

resource "tfe_workspace" "managed" {
  for_each          = { for env in local.app_env : "${env.app}-${env.environment}" => env }
  name              = each.key
  organization      = var.organization
  terraform_version = each.value.terraform_version
}
```

Run a `terraform apply`

```
terraform apply terraform apply -var "organization=YOUR-ORG" -var "workspace_name=webserver-aws-dev"
```

## Task 5: Automate Team Access across Workspaces

​
We can also utilize the tfe provider to automate applying team access across a single set of workspaces or accross all workspaces. Create an `teams.tf`

`teams.tf`

```hcl
data "tfe_team" "classmates" {
  name         = "classmates"
  organization = var.organization
}

data "tfe_workspace_ids" "all" {
  names        = ["*"]
  organization = var.organization
}

# resource "tfe_team_access" "classmates-individual" {
#   access       = "read"
#   team_id      = data.tfe_team.classmates.id
#   workspace_id = tfe_workspace.workspace_new.id
# }

resource "tfe_team_access" "classmates-all" {
  for_each     = data.tfe_workspace_ids.all.ids
  access       = "read"
  team_id      = data.tfe_team.classmates.id
  workspace_id = each.value
}
```

Run a `terraform apply`


```shell
terraform apply terraform apply -var "organization=YOUR-ORG" -var "workspace_name=webserver-aws-dev"
```
​

## Best Practices - Planning and Organizing Terraform Workspaces

​
It is recommended that organizations break down large monolithic Terraform configurations into smaller ones, then assign each one to its own workspace and delegate permissions and responsibilities for them. Terraform Cloud can manage monolithic configurations just fine, but managing infrastructure as smaller components is the best way to take full advantage of Terraform Cloud's governance and delegation features.

For example, the code that manages your production environment's infrastructure could be split into a networking configuration, the main application's configuration, and a monitoring configuration. After splitting the code, you would create "networking-prod", "app1-prod", "monitoring-prod" workspaces, and assign separate teams to manage them.

Much like splitting monolithic applications into smaller microservices, this enables teams to make changes in parallel. In addition, it makes it easier to re-use configurations to manage other environments of infrastructure ("app1-dev," etc.).
