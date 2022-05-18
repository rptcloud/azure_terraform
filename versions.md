## Description

In this challenge you will configure your Terraform code to control which versions of Terraform and Terraform providers that the code is compatible with.

Duration: 10 minutes

- Task 1: Check Terraform version
- Task 2: Require specific versions of Terraform
- Task 3: Require specific versions of Providers
- Task 4: Format and Validate Terraform Configuration
- Task 5: Validate versions of Terraform and Required Providers

## Task 1: Check Terraform version

Check the version of Terraform you are running.

```bash
terraform version
```

```bash
Terraform v1.0.8
on linux_amd64
+ provider registry.terraform.io/hashicorp/aws v3.62.0
+ provider registry.terraform.io/hashicorp/random v3.1.0
```

## Task 2: Require specific versions of Terraform

Create a Terraform configuration block within a `terraform.tf` in the `~/workstation/terraform/versions` directory to specify which version of Terraform is required to run this code base.

```bash
mkdir ~/workstation/terraform/versions && cd $_
touch {terraform,main}.tf
```

`terraform.tf`

```hcl
terraform {
  required_version = ">= 1.0.0"
}
```

This informs Terraform that it must be at least of version 1.0.0 to run the code. If Terraform is an earlier version it will throw an error. You can validate your configuration parameters easily.

```
terraform validate
```

```bash
Success! The configuration is valid.
```

## Task 3: Require specific versions of Providers

Terraform Providers are plugins that implement resource types for particular clouds, platforms and generally speaking any remote system with an API. Terraform configurations must declare which providers they require, so that Terraform can install and use them. Popular Terraform Providers include: AWS, Azure, Google Cloud, VMware, Kubernetes and Oracle.

You can update the terraform configuration block to specify a compatible AWS provider version similar to how you did for the Terraform version. Update the `terraform.tf` with a `required_providers`:

```hcl
terraform {
  required_version = ">= 1.0.0"
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}
```

By default Terraform will always pull the latest provider if no version is set. However setting a version provides a way to ensure your Terraform code remains working in the event a newer version introduces a change that
would not work with your existing code. To have more strict controls over the version you may want to require a specific version ( e.g. required_version = "= 1.0.0" ) or use the ~>operator to only allow the right-most version number to increment.

## Task 4: Format and Validate Terraform Configuration

Initialize, Format and Validate your terraform configuration by executing the following from the `~/workstation/terraform` directory in the code terminal.

```bash
cd ~/workstation/terraform/versions
terraform init -upgrade
terraform fmt -recursive
terraform validate
```

## Task 5: Validate versions of Terraform and Required Providers

To see the version of Terraform and providers installed, along with which versions are required by the current configuration you can issue the following commands:

```bash
terraform version
terraform providers
```

```bash
Providers required by configuration:
.
├── provider[registry.terraform.io/hashicorp/aws]
└── module.server
    └── provider[registry.terraform.io/hashicorp/aws] ~> 3.0

Providers required by state:

    provider[registry.terraform.io/hashicorp/aws]
```

## Task 6: Add some basic configuration objects and deploy it

Now you can add some Azure resources to the configuration and deploy them.

`main.tf`

Replace the prefix with with your initials.

```hcl
provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "training" {
  name     = "<initials>-resourcegroup"
  location = "East US"
}
```

Then run the standard workflow:

```bash
terraform plan
terraform apply
```
