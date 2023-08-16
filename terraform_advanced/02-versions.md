# Lab: Terraform Versions

## Description

In this challenge you will configure your Terraform code to control which versions of Terraform and Terraform providers that the code is compatible with.

Duration: 10 minutes

- Task 1: Check Terraform version
- Task 2: Require specific versions of Terraform
- Task 3: Require specific versions of Providers
- Task 4: Format and Validate Terraform Configuration
- Task 5: Validate versions of Terraform and Required Providers
- Task 6: Update the version of the AzureRM provider

## Task 1: Check Terraform version

Check the version of Terraform you are running.

```bash
terraform version
```

```bash
Terraform v1.5.0
on linux_amd64
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
  required_version = ">= 2.0.0"
}
```

This informs Terraform that it must be at least of version 2.0.0 to run the code. If Terraform is an earlier version it will throw an error. You can validate your configuration parameters easily.

```bash
terraform validate
```

Since we are running Terraform 1.5.0, we should see an error similar to the following:

```bash
│ Error: Unsupported Terraform Core version
│ 
│   on terraform.tf line 2, in terraform:
│    2:   required_version = ">= 2.0.0"
```

Change the `required_version` to `>= 1.0.0` and run `terraform validate` again. You should see the following output:

```bash
Success! The configuration is valid.
```

You might have noticed that we didn't initialize terraform yet! That's because we're not using any providers, so terraform doesn't need to download anything. We can still run `terraform validate` without any issues.

## Task 3: Require specific versions of Providers

Terraform Providers are plugins that implement resource types for particular clouds, platforms and generally speaking any remote system with an API. Terraform configurations must declare which providers they require, so that Terraform can install and use them. Popular Terraform Providers include: AWS, Azure, Google Cloud, VMware, Kubernetes and Oracle.

You can update the terraform configuration block to specify a compatible Azure provider version similar to how you did for the Terraform version. Update the `terraform.tf` with a `required_providers`:

`terraform.tf`

```hcl
terraform {
  required_version = ">= 1.0.0"
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "~> 2.0"
    }
  }
}
```

Now add a simple resource to the `main.tf` file.

`main.tf`

```hcl
provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "training" {
  name     = "rg-versions-test"
  location = "East US"
}
```

By default Terraform will always pull the latest provider if no version is set. However setting a version provides a way to ensure your Terraform code remains working in the event a newer version introduces a change that
would not work with your existing code. To have more strict controls over the version you may want to require a specific version ( e.g. required_version = "= 1.0.0" ) or use the ~>operator to only allow the right-most version number to increment.

## Task 4: Format and Validate Terraform Configuration

Initialize, Format and Validate your terraform configuration by executing the following from the `~/workstation/terraform/versions` directory in the code terminal.

```bash
terraform init
terraform fmt
terraform validate
```

You should see Terraform download a version of the AzureRM provider in the major version 2 family and then format and validate the configuration.

Terraform will also create a `.terraform.lock.hcl` file that contains the exact version of the provider that was downloaded. This file is used to ensure that the same version of the provider is used when running `terraform plan` or `terraform apply` in the future.

```bash
cat .terraform.lock.hcl
```

```bash
# This file is maintained automatically by "terraform init".
# Manual edits may be lost in future updates.

provider "registry.terraform.io/hashicorp/azurerm" {
  version     = "2.99.0"
  constraints = "~> 2.0"
  hashes = [
    "h1:FXBB5TkvZpZA+ZRtofPvp5IHZpz4Atw7w9J8GDgMhvk=",
    "zh:08d81e72e97351538ab4d15548942217bf0c4d3b79ad3f4c95d8f07f902d2fa6",
    "zh:11fdfa4f42d6b6f01371f336fea56f28a1db9e7b490c5ca0b352f6bbca5a27f1",
    "zh:12376e2c4b56b76098d5d713d1a4e07e748a926c4d165f0bd6f52157b1f7a7e9",
    "zh:31f1cb5b88ed1307625050e3ee7dd9948773f522a3f3bf179195d607de843ea3",
    "zh:767971161405d38412662a73ea40a422125cdc214c72fbc569bcfbea6e66c366",
    "zh:973c402c3728b68c980ea537319b703c009b902a981b0067fbc64e04a90e434c",
    "zh:9ec62a4f82ec1e92bceeff80dd8783f61de0a94665c133f7c7a7a68bda9cdbd6",
    "zh:bbb3b7e1229c531c4634338e4fc81b28bce58312eb843a931a4420abe42d5b7e",
    "zh:cbbe02cd410d21476b3a081b5fa74b4f1b3d9d79b00214009028d60e859c19a3",
    "zh:cc00ecc7617a55543b60a0da1196ea92df48c399bcadbedf04c783e3d47c6e08",
    "zh:eecb9fd0e7509c7fd4763e546ef0933f125770cbab2b46152416e23d5ec9dd53",
  ]
}
```

Terraform will use this version of the provider until you change the constraint or run `terraform init -upgrade` to upgrade to a newer version.

## Task 5: Validate versions of Terraform and Required Providers

To see the version of Terraform and providers installed, along with which versions are required by the current configuration you can issue the following commands:

```bash
terraform version
terraform providers
```

```bash
Providers required by configuration:
.
└── provider[registry.terraform.io/hashicorp/azurerm] ~> 2.0
```

## Task 6: Update the version of the AzureRM provider

We set Terraform to use major version 2 of the AzureRM provider, but now we're ready to upgrade to version 3. First we need to change the version constraint in our `terraform.tf` file.

`terraform.tf`

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

If we try to run a `terraform plan` now before we update the provider plugin and lock file we will get an error:

```bash
terraform plan
```

```bash
│ Error: Inconsistent dependency lock file
│ 
│ The following dependency selections recorded in the lock file are inconsistent with the current configuration:
│   - provider registry.terraform.io/hashicorp/azurerm: locked version selection 2.99.0 doesn't match the updated version constraints "~> 3.0"
```

To upgrade the locally installed provider, we need to run `terraform init -upgrade`.

```bash
terraform init -upgrade
```

```bash
...
Initializing provider plugins...
- Finding hashicorp/azurerm versions matching "~> 3.0"...
- Installing hashicorp/azurerm v3.69.0...
- Installed hashicorp/azurerm v3.69.0 (signed by HashiCorp)

Terraform has made some changes to the provider dependency selections recorded
in the .terraform.lock.hcl file. Review those changes and commit them to your
version control system if they represent changes you intended to make.
...
```

Now we can run `terraform plan` and it will execute successfully.

```bash
terraform plan
```

You do not need to actually deploy the configuration, unless you really want to.