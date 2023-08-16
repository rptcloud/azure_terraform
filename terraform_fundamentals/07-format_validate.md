# Lab: Variables and Locals

Duration: 10 minutes

You can use the `terraform fmt` and `terraform validate` commands to check the formatting and syntax of your configuration.

- Task 1: Update formatting
- Task 2: Run validation

## Task 1: Update formatting

From the terminal of your lab, run the following command to check the formatting of your configuration:

```bash
terraform fmt -check
```

The `-check` flag checks the formatting without applying any changes. If there are any formatting errors, you will see an error message.

Now run the `terraform fmt` command without the `-check` flag to apply the formatting changes:

```bash
terraform fmt
```

By default `terraform fmt` will only check and update files in the working directory. You can use the `-recursive` flag to recursively check and update all files in the working directory and subdirectories.

## Task 2: Run validation

Your current configuration should be valid, so let's introduce a couple errors to see how Terraform responds. Open the `main.tf` file in your editor and make the following changes:

```hcl
resource "azurerm_resource_group" "training" {
  name     = var.missing_variable
  location = var.location
  bad_argument = "bad"
}
```

Run `terraform validate` to check the syntax of your configuration:

```bash
terraform validate
```

You will see output similar to this:

```bash
│ Error: Reference to undeclared input variable
│ 
│   on main.tf line 6, in resource "azurerm_resource_group" "training":
│    6:   name     = var.missing_variable
│ 
│ An input variable with the name "missing_variable" has not been declared. This variable can be declared with a variable "missing_variable" {}
│ block.
```

Resolve the issues by changing the block back to it's previous state:

```hcl
resource "azurerm_resource_group" "training" {
  name     = var.resource_group_name
  location = var.location
}
```

Then run `terraform validate` again to confirm that the configuration is valid:

```bash
terraform validate
```

You should see output similar to this:

```bash
Success! The configuration is valid.
```
