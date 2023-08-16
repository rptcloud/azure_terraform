# Lab: Terraform Console

Duration: 10 minutes

- Task 1: Run and explore the `terraform console` command
- Task 2: Use the REPL console to test expressions

## Task 1: Run and explore the `terraform console` command

Run the `terraform console` command to start the REPL console.

```bash
terraform console
```

Then try view the attributes of a resource.

```bash
azurerm_virtual_machine.training.storage_image_reference
```

You should see output that looks like this:

```bash
[
  {
    "id" = ""
    "offer" = "UbuntuServer"
    "publisher" = "Canonical"
    "sku" = "16.04.0-LTS"
    "version" = "latest"
  },
]
```

## Task 2: Use the REPL console to test expressions

From the console try some of the following expressions:

```bash
1 + 1
lower("HELLO")
upper(azurerm_resource_group.training.name)
```

You can reference the outputs and resources of the configuration in your functions and expressions. Try a few more!
