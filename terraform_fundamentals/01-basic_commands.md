# Lab: Basic Commands

Duration: 10 minutes

- Task 1: Use the Terraform CLI to run commands
- Task 2: Explore the help function of the Terraform CLI
- Task 3: View the Azure subscription details

## Task 1: Use the Terraform CLI to run commands

From the terminal in the lab environment, run the following command to view the current Terraform version:

```bash
terraform version
```

Run terraform by itself to view the available commands:

```bash
terraform
```

## Task 2: Explore the help function of the Terraform CLI

From the terminal run the following command to view general help:

```bash
terraform -help
```

*Notice that you don't need a double dash for CLI options.*

Now try and get help for a specific command:

```bash
terraform plan -help
```

Try a few other commands to get a feel for the CLI.

## Task 3: View the Azure subscription details

Your lab environment has an Azure subscription already configured. Run the following command to view the details of the subscription:

```bash
env | grep ARM
```

Terraform knows to look for their environment variables and use them for authentication to Azure.