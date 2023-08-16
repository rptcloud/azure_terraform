# Lab: Azure Authentication

Duration: 5 minutes

In this lab, you will explore how Terraform is authenticating to Azure.

- Task 1: View the current environment variables

## Task 1: View the current environment variables

From the terminal of you lab environment, run the following command to view the current environment variables:

```bash
env | grep ARM
```

You should see environment variables for the Azure subscription ID, tenant ID, client ID, and client secret.

From the cloud credentials tab, you can confirm that the values line up to what was provisioned for you.

## Bonus Task: Override the environment variables

You can also set the Azure authentication values directly in the provider block. Although this isn't recommended, it can be useful for testing. Add the necessary arguments in the `azurerm` provider block and use input variables to set the values.
