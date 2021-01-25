# Lab: Null Resource

Duration: 15 minutes

This lab demonstrates the use of the `null_resource`. Instances of `null_resource` are treated like normal resources, but they don't do anything. Like with any other resource, you can configure provisioners and connection details on a null_resource. You can also use its triggers argument and any meta-arguments to control exactly where in the dependency graph its provisioners will run.

- Task 1: Create a Azure Virtual Macine using Terraform
- Task 2: Use `null_resource` with a VM to take action with `triggers`.

We'll demonstrate how `null_resource` can be used to take action on a set of existing resources that are specified within the `triggers` argument


## Task 1: Create a Google Instance using Terraform
### Step 11.1.1: Create Server instances

Build the web servers using the Azure Virtual Machine Module (previous labs)

You can see this now if you run `terraform apply`:

```text
...

Apply complete! Resources: 0 added, 0 changed, 0 destroyed.

...
```


## Task 2: Use `null_resource` with a Azure Virtual Machine to take action with `triggers`
### Step 11.2.1: Use `null_resource`

Add `null_resource` stanza to the `main.tf`.  Notice that the trigger for this resource is set to 

```hcl
resource "null_resource" "web_cluster" {
  # Changes to any instance of the cluster requires re-provisioning
  triggers = {
    web_cluster_size = length(azurerm_virtual_machine.training)
  }

  # Bootstrap script can run on any instance of the cluster
  # So we just choose the first in this case
  connection {
    host = element(google_compute_instance.web[*].network_interface[0].access_config[0].nat_ip, 0)
  }

  provisioner "local-exec" {
    # Bootstrap script called with private_ip of each node in the clutser
    command = "echo ${join(" Cluster local IP is : ", google_compute_instance.web[*].network_interface.0.network_ip)}"
  }
}
```
Initialize the configuration with a `terraform init` followed by a `plan` and `apply`.

### Step 11.2.2: Re-run `plan` and `apply` to trigger `null_resource`
After the infrastructure has completed its buildout, change your machine count (in your terraform.tfvars) and re-run a plan and apply and notice that the null resource is triggered.  This is because the "cluster size" changed, triggering our null_resource.

```shell
terraform apply
```

Run `apply` a few times to see the `null_resource`.

### Step 11.2.3: Destroy
Finally, run `destroy`.

```shell
terraform destroy
```