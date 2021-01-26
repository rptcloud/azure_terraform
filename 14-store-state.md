# Lab: Store State Remotely on Terraform Cloud

Duration: 20 minutes

This lab demonstrates how to store state on Terraform Cloud and read from it.
You'll setup a new project using Terraform Cloud as your backed and use a second project to read from it.

- Task 1: Create a Terraform Cloud user token
- Task 2: Create a configuration which stores its state on Terraform Cloud
- Task 3: Create another Terraform config that reads from the state on Terraform Cloud

## Prerequisites

For this lab, we'll assume that you've installed [Terraform](https://www.terraform.io/downloads.html) and that you have [signed up](https://app.terraform.io/signup/account) for a Terraform Cloud account.

## Task 1: Create a Terraform Cloud user token

In order to store state remotely on Terraform Cloud, we need to create a user token and configure our local environment to utilize that token.

**NOTE:** Terraform Cloud only works with 0.11.13 or later.

### Step 2.1.1:

**Note:** You can skip this step if you've already created a organization.

[Log in](https://app.terraform.io) to Terraform Cloud and go to the new organization page:

* New users are automatically taken to the new organization page.
* If your user account is already a member of an organization, open the organization switcher menu in the top navigation bar and click the "Create new organization" button.

Enter a unique organization name and an email address for notifications, then click the "Create organization" button.

![New Organization](images/free-org-creation.png "New Organization")

### Step 2.1.2:

Terraform's CLI needs credentials before it can access Terraform Cloud.
First we will create the Terraform CLI configuration file:

```shell
touch ~/.terraformrc
```

In this file, we will add the following credentials block:

```bash
credentials "app.terraform.io" {
  token = "REPLACE_ME"
}
```

Leave your editor open.

### Step 2.1.3

In your web browser, go to the [tokens section](https://app.terraform.io/app/settings/tokens) of your user settings or click the user icon in the upper right corner, click "User Settings", then click "Tokens" in the left sidebar.

Generate a new token by entering a description and clicking the "Generate token" button.
The new token will appear in a text area below the description field.

Copy the token to the clipboard.

In your text editor, paste the real token into the token argument, replacing the `REPLACE_ME` placeholder. Save the CLI config file and close your editor.

### Step 2.1.4

At this point, Terraform can use Terraform Cloud with any Terraform configuration that has enabled the remote backend.

Update the permissions of the CLI config file to `0600` with:

```shell
chmod 0600 ~/.terraformrc
```

## Task 2: Create a configuration which stores its state on Terraform Cloud

For this task, you'll create a Terraform project which stores its state in Terraform Cloud and emits an output.

### Step 2.2.1

In this step, you'll create the project and a configuration.

```shell
mkdir -p /workstation/terraform/azure/cloud_state_demo/write_state && cd $_
touch main.tf
```

### Step 2.2.2

Setup the configuration to utilize the `remote` backend, replacing `ORGANIZATION NAME` with the name of your organization and ```###``` with your initials.

```hcl
# write_state/main.tf
terraform {
  backend "remote" {
    organization = "<ORGANIZATION NAME>"

    workspaces {
      name = "###_write_state"
    }
  }
}
```

### Step 2.2.3

Next, add the ability to generate and emit a `random` output from your configuration:

```hcl
# write_state/main.tf
resource "random_id" "random" {
  keepers = {
    uuid = uuid()
  }

  byte_length = 8
}

output "random" {
  value = random_id.random.hex
}
```

### Step 2.2.4

Provision the resource and push the state to Terraform Cloud with:

```shell
terraform init
terraform apply -auto-approve
```

You'll see Terraform confirm it is creating your state remotely as well as your `random` output.
If you navigate back to your organization, you will also see a new workspace name `###_write_state`.

### Step 2.2.5

Congratulations!
You're now storing state remotely.
With Terraform Cloud you are able to share your workspace with teammates.
Back in the Terraform Cloud UI you'll be able to:

* View all your organization's workspaces
* Lock a workspace, making it easy to avoid conflicting changes and state corruption
* View state history

## Task 3: Create another Terraform config that reads from the state on Terraform Cloud

Now that we have our state stored in Terraform Cloud in our `###_write_state` workspace, we will create another project, configuration, and workspace to read from it.

### Step 2.3.1

Start by creating a new directory and `main.tf` file:

```shell
mkdir -p /workstation/terraform/azure/cloud_state_demo/read_state && cd $_
touch main.tf
```

### Step 2.3.2

Just as we did in Step 2.2.2, we need to setup our configuration to use the `remote` backend, once again replacing `ORGANIZATION NAME`.
We will also create a new `random` resource to compare against:

```hcl
# read_state/main.tf
terraform {
  backend "remote" {
    organization = "<ORGANIZATION NAME>"

    workspaces {
      name = "###_read_state"
    }
  }
}

resource "random_id" "random" {
  keepers = {
    uuid = uuid()
  }

  byte_length = 8
}
```

### Step 2.3.3

In order to read from our `###_write_state` workspace, we will need to setup a `terraform_remote_state` data source.
Data sources are used to retrieve read-only data from sources outside of our project.
It supports several cloud providers, but we'll be using `remote` as the `backend`.

```hcl
# read_state/main.tf
data "terraform_remote_state" "write_state" {
  backend = "remote"

  config = {
    organization = "<ORGANIZATION NAME>"

    workspaces = {
      name = "###_write_state"
    }
  }
}
```

### Step 2.3.4

Now that we have access to our remote `###_write_state` workspace, we can retrieve the `random` output contained within it.
We'll also output `random` which we created in this configuration, confirming that they are distinct.

```hcl
# read_state/main.tf
output "random" {
  value = random_id.random.hex
}

output "write_state_random" {
  value = data.terraform_remote_state.write_state.outputs.random
}
```

### Step 2.3.5

To verify that we have successfully retrieved the state from out `###_write_state` workspace, we can run our configuration and validate our outputs.

Run `init` again to install the necessary supporting files.

```shell
terraform init
terraform apply -auto-approve
```

```text
Apply complete! Resources: 1 added, 0 changed, 0 destroyed.

Outputs:
random = c1597ca0fbba3997
write_state_random = 0de9168d0b78ead6
```

It worked!
You've now successfully stored your states remotely and read from those remote states.
