# Lab: Outputs

Duration: 10 minutes

- Task 1: Create and return a new output variables
- Task 2: Use `terraform output` to query for specific output

Create and return a new output variable

### 1. Create a new output variable named "public_dns" which outputs the instance's public_dns attribute

Create a new file called `outputs.tf` and add the following code:

```terraform
output "public_dns" {
  value = azurerm_public_ip.training.fqdn
}
```

### 2. Run `terraform apply -refresh-only` to view the defined resource output

```bash
terraform apply -refresh-only
```

### 3. Query for specific output using `terraform output`

```bash
terraform output public_dns
ping $(terraform output -raw public_dns)
```
