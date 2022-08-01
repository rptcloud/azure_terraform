# Using Terraform Provisioner

## Expected Outcome

In this challenge, you will create a Azure Virtual Machine but this time layer in Terraform Provisioners to configure the machines as part the Terraform apply.

## Background

Terraform [provisioners](https://www.terraform.io/docs/provisioners/index.html) help you do additional setup and configuration when a resource is created or destroyed.
You can move files, run shell scripts, and install software.

Provisioners are not intended to maintain desired state and configuration for existing resources.
For that purpose, you should use one of the many tools for configuration management, such as [Chef](https://www.chef.io/chef/), [Ansible](https://www.ansible.com/), and PowerShell [Desired State Configuration](https://docs.microsoft.com/en-us/powershell/dsc/overview/overview).
Terraform includes [provisioners](https://www.terraform.io/docs/language/resources/provisioners/index.html) for Chef, Habitat, Puppet, and Salt.

An imaged-based infrastructure, such as images created with [Packer](https://www.packer.io), can eliminate much of the need to configure resources when they are created.
In this common scenario, Terraform is used to provision infrastructure based on a custom image.
The image is managed as code.

## How To

### Defining a provisioner

Provisioners are defined on resources, most commonly a new instance of a virtual machine or container.

The complete configuration for this example is given below.
By now, you should be familiar with most of the contents.

Notice that the azurerm_virtual_machine resource contains two provisioner blocks:

```hcl
resource "azurerm_virtual_machine" "vm" {
...
  provisioner "file" {
    connection {
      host     = azurerm_public_ip.training.fqdn
      type     = "ssh"
      user     = var.admin_username
      password = var.admin_password
    }

    source      = "hello.py"
    destination = "hello.py"
  }

  provisioner "remote-exec" {
    connection {
      host     = azurerm_public_ip.training.fqdn
      type     = "ssh"
      user     = var.admin_username
      password = var.admin_password
    }

    inline = [
      "python3 -V",
      "sudo apt update",
      "sudo apt install -y python3-pip python3-flask",
      "python3 -m flask --version",
      "sudo FLASK_APP=hello.py nohup flask run --host=0.0.0.0 --port=8000 &",
      "sleep 1"
    ]
  }
}
```

As this example shows, you can define more than one provisioner in a resource block.
The [file](https://www.terraform.io/docs/provisioners/file.html) and [remote-exec](https://www.terraform.io/docs/provisioners/remote-exec.html) providers are used to perform two simple setup tasks:

-   File copies a python file from the machine that is running Terraform to the new VM instance.
-   Remote-exec runs commands to start a python flask app.

Both providers need a [connection](https://www.terraform.io/docs/provisioners/connection.html) to the new virtual machine to do their jobs.
To simplify things, the example uses password authentication.
In practice, you are more likely to use SSH keys (or for WinRM connections, use certificates) to authenticate.

### Running provisioners

Provisioners run when a resource is created, or a resource is destroyed.
Provisioners do not run during update operations.
The example configuration for this section defines two provisioners that run only when a new virtual machine instance is created.
If the virtual machine instance is later modified or destroyed, the provisioners will not run.

For this lab, the full configuration is:

```hcl
variable "prefix" {
  description = "Unique prefix, no dashes or numbers please."
}

variable "location" {}
variable "admin_username" {}
variable "admin_password" {}

provider azurerm {
  features {}
}

# Create a resource group
resource "azurerm_resource_group" "rg" {
  name     = "${var.prefix}-provisioner-rg"
  location = var.location
}
# Create virtual network
resource "azurerm_virtual_network" "vnet" {
  name                = "${var.prefix}TFVnet"
  address_space       = ["10.0.0.0/16"]
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
}

# Create subnet
resource "azurerm_subnet" "subnet" {
  name                 = "${var.prefix}TFSubnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Create public IP
resource "azurerm_public_ip" "publicip" {
  name                = "${var.prefix}publicipprovision"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Dynamic"
  domain_name_label   = "${lower(var.prefix)}publicipprovision"
}

# Create Network Security Group and rules
resource "azurerm_network_security_group" "nsg" {
  name                = "${var.prefix}TFNSG"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_network_security_rule" "ssh" {
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.nsg.name
  name                        = "SSH"
  priority                    = 1001
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "22"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
}

resource "azurerm_network_security_rule" "app" {
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.nsg.name
  name                        = "App"
  priority                    = 1002
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "8000"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
}

# Create network interface
resource "azurerm_network_interface" "nic" {
  name                      = "${var.prefix}NIC"
  location                  = var.location
  resource_group_name       = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "${var.prefix}NICConfg"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.publicip.id
  }
}

# Create a Linux virtual machine
resource "azurerm_virtual_machine" "vm" {
  name                  = "${var.prefix}TFVM"
  location              = var.location
  resource_group_name   = azurerm_resource_group.rg.name
  network_interface_ids = [azurerm_network_interface.nic.id]
  vm_size               = "Standard_DS1_v2"

  delete_os_disk_on_termination = true
  storage_os_disk {
    name              = "${var.prefix}OsDisk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Premium_LRS"
  }

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  os_profile {
    computer_name  = "${var.prefix}TFVM"
    admin_username = var.admin_username
    admin_password = var.admin_password
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }

  provisioner "file" {
    connection {
      host     = azurerm_public_ip.publicip.fqdn
      type     = "ssh"
      user     = var.admin_username
      password = var.admin_password
    }

    source      = "hello.py"
    destination = "hello.py"
  }

  provisioner "remote-exec" {
    connection {
      host     = azurerm_public_ip.publicip.fqdn
      type     = "ssh"
      user     = var.admin_username
      password = var.admin_password
    }

    inline = [
      "python3 -V",
      "sudo apt update",
      "sudo apt install -y python3-pip python3-flask",
      "python3 -m flask --version",
      "sudo FLASK_APP=hello.py nohup flask run --host=0.0.0.0 --port=8000 &",
      "sleep 1"
    ]
  }
}

output "app-URL" {
  value = "http://${azurerm_public_ip.publicip.fqdn}:8000"
}
```

To run the example configuration with provisioners:

1.  Copy the configuration to a file named `main.tf`. It should be the only `.tf` file in the folder.
2.  Create a `terraform.tfvars` with the following items, replacing **`###`** with your initials
   ```hcl
   prefix              = "###"
   location            = "East US"
   admin_username      = "testadmin"
   admin_password      = "Password1234!"
   ```
3.  Create a file named `hello.py`.
    1.  In the editor, add the following text: 
    ```py
    from flask import Flask
    import requests

    app = Flask(__name__)

    import requests
    @app.route('/')
    def hello_world():
        return """<!DOCTYPE html>
    <html>
    <head>
        <title>Kittens</title>
    </head>
    <body>
        <img src="http://placekitten.com/200/300" alt="User Image">
    </body>
    </html>"""
    ``` 
    1.  Save the file and close the editor.
4.  Run `terraform init`
5.  Run `terraform plan`
6.  Run `terraform apply`. When prompted to continue, answer `yes`.

The following sample output has been truncated to show only the end of the output added by the provisioners (your actual output may differ slightly):

```
...

azurerm_virtual_machine.vm (remote-exec): Processing triggers for mime-support (3.60ubuntu1) ...
azurerm_virtual_machine.vm (remote-exec): Processing triggers for libc-bin (2.27-3ubuntu1) ...

azurerm_virtual_machine.vm (remote-exec): Flask 0.12.2
azurerm_virtual_machine.vm (remote-exec): Python 3.6.8 (default, Aug 20 2019, 17:12:48)
azurerm_virtual_machine.vm (remote-exec): [GCC 8.3.0]
azurerm_virtual_machine.vm (remote-exec): nohup: appending output to 'nohup.out'

Apply complete!

```

Continue the procedure from above by doing the following:

1.  Run `terraform show` to examine the current state.
2.  Update the image src in the flask app to return a different image (Replace `http://placekitten.com/200/300` - try `https://i1.wp.com/www.thedevcoach.co.uk/wp-content/uploads/2020/04/What-is-Terraform.png`).
3.  Update your provisioner text file and run a `terraform plan`. Were the results as expected?


### Failed provisioners and tainted resources

Provisioners sometimes fail to run properly.
By the time the provisioner is run, the resource has already been physically created.
If the provisioner fails, the resource will be left in an unknown state.
When this happens, Terraform will generate an error and mark the resource as "tainted."
A resource that is tainted isn't considered safe to use.

When you generate your next execution plan, Terraform will not attempt to restart provisioning on the tainted resource because it isn't guaranteed to be safe.
Instead, Terraform will remove any tainted resources and create new resources, attempting to provision them again after creation.

You might wonder why Terraform doesn't destroy the tainted resource during apply, to avoid leaving a resource in an unknown state.
Terraform doesn't roll back tainted resources because that action was not in the execution plan.
The execution plan says that a resource will be created, but not that it might be deleted.
If you create an execution plan with a tainted resource, however, the plan will clearly state that the resource will be destroyed because it is tainted.

For our tainting lab, we will use our `vm` from the above configuration.
We will list our resources, taint the appropriate `vm` resource, and apply.

List the resources in our state:
```shell
terraform state list
```

Find the appropriate resource:
```text
...
azurerm_subnet.subnet
azurerm_virtual_machine.vm
azurerm_virtual_network.vnet
```

Replace our VM using the `terraform apply -replace` option:

```shell
terraform apply -replace azurerm_virtual_machine.vm
```

```text
Plan: 1 to add, 0 to change, 1 to destroy.
...
Outputs:

app-URL = http://ccqpublicipprovision.eastus.cloudapp.azure.com:8000
```

Go to the URL provided in the output.
Which image do you see now?

### Destroy Provisioners

Provisioners can also be defined that run only during a destroy operation.
These are known as [destroy-time provisioners](https://www.terraform.io/docs/language/resources/provisioners/syntax.html#destroy-time-provisioners).
Destroy provisioners are useful for performing system cleanup, extracting data, etc.

The following code snippet shows how a destroy provisioner is defined:

```
provisioner "remote-exec" {
    when = "destroy"
...
```

### Clean up

When you are done, run `terraform destroy` to remove everything we created.
