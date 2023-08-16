# Lab: Terraform Cloud Variables

In this lab, we will populate the input variable values for our Terraform Cloud workspace.

Duration: 10 minutes

- Task 1: Populate Azure Credentials with Environment Variables
- Task 2: Set the prefix variable with a new value and apply changes

## Task 1: Populate Azure Credentials with Environment Variables

Get the current values of the Azure environment variables:

```bash
env | grep ARM
```

Go to the workspace in Terraform Cloud. On the variables tab, add the following environment variables for the Azure provider. Be sure to select environment as the variable type for each one, and set `ARM_CLIENT_SECRET` to sensitive:

- `ARM_CLIENT_ID`
- `ARM_CLIENT_SECRET`
- `ARM_SUBSCRIPTION_ID`
- `ARM_TENANT_ID`

## Task 2: Set the prefix variable with a new value and apply changes

In the workspace, create another variable called `prefix` of type `terraform`. Set it to a value other than your initials.

From the terminal of the lab environment, kick off a new terraform apply:

```bash
terraform apply
```

When the apply phase prompts for approval, go to the Terraform Cloud workspace and approve the run from there.
