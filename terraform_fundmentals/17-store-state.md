# Lab: Store State Remotely on Terraform Cloud

Duration: 20 minutes

This lab demonstrates how to store state on Terraform Cloud and read from it.
You'll setup a new project using Terraform Cloud as your backed and use a second project to read from it.

- Task 1: Create a Terraform Cloud user token
- Task 2: Create a configuration which stores its state on Terraform Cloud
- Task 3: Create another Terraform config that reads from the state on Terraform Cloud

## Task 1: Sign up for Terraform Cloud

1. Navigate to [the sign up page](https://app.terraform.io/signup) and create an account for Terraform Cloud and an organization called `###-tfc-demo-2023` where `###` is your initials. If you already have an account, just create the organization.

1. Perform a `terraform login` from your workstation

```bash
Terraform will request an API token for app.terraform.io using your browser.

If login is successful, Terraform will store the token in plain text in
the following file for use by subsequent commands:
    /home/student/.terraform.d/credentials.tfrc.json

Do you want to proceed?
  Only 'yes' will be accepted to confirm.

  Enter a value:
```

2. Answer `yes` at the prompt and generate a TFC user token by following the URL provided and copy-paste it into the prompt.

```bash
---------------------------------------------------------------------------------

Open the following URL to access the tokens page for app.terraform.io:
    https://app.terraform.io/app/settings/tokens?source=terraform-login


---------------------------------------------------------------------------------
```

1. If the token was entered successfully you should see the following:

```bash

Retrieved token for user tfcuser


---------------------------------------------------------------------------------

                                          -
                                          -----                           -
                                          ---------                      --
                                          ---------  -                -----
                                           ---------  ------        -------
                                             -------  ---------  ----------
                                                ----  ---------- ----------
                                                  --  ---------- ----------
   Welcome to Terraform Cloud!                     -  ---------- -------
                                                      ---  ----- ---
   Documentation: terraform.io/docs/cloud             --------   -
                                                      ----------
                                                      ----------
                                                       ---------
                                                           -----
                                                               -


   New to TFC? Follow these steps to instantly apply an example configuration:

   $ git clone https://github.com/hashicorp/tfc-getting-started.git
   $ cd tfc-getting-started
   $ scripts/setup.sh

```

## Task 2: Create a configuration which stores its state on Terraform Cloud

For this task, you'll create a Terraform project which stores its state in Terraform Cloud and emits an output.

### Step 2.1

In this step, you'll create the project and a configuration.

```bash
mkdir -p ~/workstation/terraform/azure/cloud_state_demo/write_state && cd $_
touch main.tf
```

### Step 2.2

Setup the configuration to utilize the `remote` backend, replacing `ORGANIZATION NAME` with the name of your organization and ```###``` with your initials.

```hcl
# write_state/main.tf
terraform {
  cloud {
    organization = "<ORGANIZATION NAME>"

    workspaces {
      name = "###_write_state"
    }
  }
}
```

### Step 2.3

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

### Step 2.4

Provision the resource and push the state to Terraform Cloud with:

```shell
terraform init
terraform apply -auto-approve
```

You'll see Terraform confirm it is creating your state remotely as well as your `random` output.
If you navigate back to your organization, you will also see a new workspace name `###_write_state`.

### Step 2.5

Congratulations! You're now storing state remotely. With Terraform Cloud you are able to share your workspace with teammates.

Back in the Terraform Cloud UI you'll be able to:

* View all your organization's workspaces
* Lock a workspace, making it easy to avoid conflicting changes and state corruption
* View state history

## Task 3: Create another Terraform config that reads from the state on Terraform Cloud

Now that we have our state stored in Terraform Cloud in our `###_write_state` workspace, we will create another project, configuration, and workspace to read from it.

### Step 3.1

Start by creating a new directory and `main.tf` file:

```shell
mkdir -p ~/workstation/terraform/azure/cloud_state_demo/read_state && cd $_
touch main.tf
```

### Step 3.2

Just as we did in Step 2.2.2, we need to setup our configuration to use the `remote` backend, once again replacing `ORGANIZATION NAME`.
We will also create a new `random` resource to compare against:

```hcl
# read_state/main.tf
terraform {
  cloud {
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

### Step 3.3

In order to read from our `###_write_state` workspace, we will need to setup a `terraform_remote_state` data source.
Data sources are used to retrieve read-only data from sources outside of our project.

It supports several cloud providers, but we'll be using `remote` as the `backend`. That is the name of the Terraform Cloud backend.

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

In addition to creating the `terraform_remote_state` data source in your configuration, you will also need to change the workspace settings for you `###_write_state` workspace to allow other workspaces to access its state data.

From the Terraform Cloud UI, go to the `###_write_state` workspace, and select *Settings->General*. Under the *Remote state sharing* section change the radio button to **Share with all workspaces in this organization**, then click on *Save settings* at the bottom of the page.

### Step 3.4

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

### Step 3.5

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
