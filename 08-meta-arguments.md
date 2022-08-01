# Lab 8: Meta-Arguments

Duration: 10 minutes

So far, we've already used arguments to configure your resources. These arguments are used by the provider to specify things like the image to use, and the type of instance to provision. Terraform also supports a number of _Meta-Arguments_, which changes the way Terraform configures the resources. For instance, it's not uncommon to provision multiple copies of the same resource. We can do that with the _count_ argument.

- Task 1: Change the number of Virtul Machines with `count`
- Task 2: Modify the rest of the configuration to support multiple instances
- Task 3: Add variable interpolation to the count arguement

## Task 1: Change the number of Azure Virtual Machines with `count`

### Step 8.1.1

Add a count argument to the Azure Virtual Machine resource in `main.tf` with a value of 2.  Also adjust the value of `name` to incrementally add a number to the end of each instances name: 

```hcl
# ...
resource "azurerm_virtual_machine" "training" {
  count                 = 2
  name                  = "${var.prefix}vm-${count.index + 1}"
  location              = azurerm_resource_group.training.location
  resource_group_name   = azurerm_resource_group.training.name
  network_interface_ids = [azurerm_network_interface.training[count.index].id]
  vm_size               = "Standard_D2s_v4"
# ... leave the rest of the resource block unchanged...
}

The name of the storage disk also needs to be updated to reflect the use of count: 

storage_os_disk {
    name              = "${var.prefix}disk-${count.index + 1}"
  # ... leave the rest of the resource block unchanged...
```

as well as the public_ip, network interface

```hcl
resource "azurerm_public_ip" "training" {
  count                   = 2
  name                    = "azureuser${var.prefix}ip-${count.index + 1}"
  location                = azurerm_resource_group.training.location
  resource_group_name     = azurerm_resource_group.training.name
  allocation_method       = "Dynamic"
  idle_timeout_in_minutes = 30
  domain_name_label       = "azureuser${var.prefix}domain${count.index + 1}"
}

resource "azurerm_network_interface" "training" {
  count               = 2
  name                = "azureuser${var.prefix}ni-${count.index + 1}"
  location            = azurerm_resource_group.training.location
  resource_group_name = azurerm_resource_group.training.name

  ip_configuration {
    name                          = "azureuser${var.prefix}ip"
    subnet_id                     = azurerm_subnet.training.id
    private_ip_address_allocation = "dynamic"
    #private_ip_address            = "10.0.2.5"
    public_ip_address_id          = azurerm_public_ip.training[count.index].id
  }
}

```

## Task 2: Modify the rest of the configuration to support multiple instances

### Step 8.2.1

If you run `terraform apply` now, you'll get an error. Since we added _count_ to the azure_virtual_machine.training resource, it now refers to multiple resources. Because of this, values like our public_dns output no longer refer to the "public dns" of a single resource. We need to tell terraform which resource we're referring to.

To do so, modify the output blocks in `main.tf` as follows:

```hcl
output "public_dns" {
  value = azurerm_public_ip.training[*].fqdn
}
```

The syntax `azurerm_public_ip.training[*]...` refers to all of the instances, so this will output a list of all dns entries. 

### Step 8.2.2

Run `terraform apply` to add the new instance. You will notice that because we changed the name of the Azure Virtual Mahine, that there will be a forced replacement of our previous virutal machine.

```text
Plan: 2 to add, 0 to change, 1 to destroy.
```

You should see two dns addresses in the outputs, one for each virtual machine.

```text
Plan: 2 to add, 0 to change, 1 to destroy.
```

## Task 3: Add variable interpolation to the count arguement

### Step 8.3.1

Update `variables.tf` to add a new variable definition, and use it:

```hcl
# ...
variable "num_vms" {
  default = 2
}
```
Update `main.tf`
```hcl
resource "azurerm_public_ip" "training" {
  count                   = var.num_vms
# ...

resource "azurerm_network_interface" "training" {
  count               = var.num_vms
# ...  

resource "azurerm_virtual_machine" "training" {
  count        = var.num_vms
  name         = "${var.prefix}vm-${count.index + 1}"
# ...


```

The solution builds on our previous discussion of variables. We must create a
variable to hold our count so that we can reference that count in our
resource. Next, we replace the value of the count parameter with the variable
interpolation. Finally, we interpolate the current count (+ 1 because it's
zero-indexed) and the variable itself.

Remember to also add the variable declaration to your `terraform.tfvars` accordingly.

```hcl
num_vms = 2
```

### Step 8.3.2

Run `terraform apply` in the terraform directory. No changes should be detected as the _values_ have not changed:

```shell
terraform apply
```

```text
No changes. Infrastructure is up-to-date.

This means that Terraform did not detect any differences between your
configuration and real physical resources that exist. As a result, no
actions need to be performed.
```
