# Lab: Automated Testing

We may want to test our infrastructure to ensure it is healthy and behaving how we want it to.

Duration: 15 minutes

- Task 1: Write a Terraform Module
- Task 2: Write a unit test for your Terraform module
- Task 3: Use Terratest to Deploy infrastructure
- Task 4: Validate infrastructure with Terratest
- Task 5: Undeploy

The only real way to test infrastructure code beyond static analysis is by deploying it to a real environment, whatever environment you happen to be using.

[Terratest](https://terratest.gruntwork.io) is a Go library that provides patterns and helper functions for testing infrastructure, with 1st-class support for Terraform, Packer, Docker, Kubernetes, AWS, GCP, and more.

## Task 1: Write a Terraform Module

First, ensure you are in the `~/workstation/terraform/` directory on your workstation. Inside of the `~/workstation/terraform/` directory create a `testing_lab` folder add a `main.tf` calling a module that we will be writing and testing.

### Root Module
```shell
mkdir -p ~/workstation/terraform/testing_lab
touch ~/workstation/terraform/testing_lab/main.tf
```

`main.tf`

```terraform
module "myawesomelinuxvm" {
  source   = "./modules/my_linux_vm"
  prefix   = "###-testing"
  location = "East US"
  vm_size  = "Standard_A2_v2"
  admin_username      = "testadmin"
  admin_password      = "Password1234!" 
}
```

Update the `###` in the prefix with your initials.

### Linux VM with Flask App Module for Testing

Create a Module for building a Linux VM with a Flask Application that will be the source of our unit tests.

```shell
mkdir -p ~/workstation/terraform/testing_lab/modules/my_linux_vm
touch ~/workstation/terraform/testing_lab/modules/my_linux_vm/{linux,variables,outputs,terraform}.tf
touch ~/workstation/terraform/testing_lab/modules/my_linux_vm/hello.py
```

The structure for this module testing will look similar to the following file layout:

```sh
testing_lab
├── main.tf
├── modules
│   └── my_linux_vm
|          └── linux.tf
|          └── variables.tf
|          └── outputs.tf
|          └── hello.py
├── terraform.tfvars
└── variables.tf
```

Insided the `my_linux_vm` directory update the terraform configuration files as follows:

`linux.tf`
```terraform
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
```

`variables.tf`
```terraform
variable "prefix" {
  description = "Unique prefix, no dashes or numbers please."
}
variable "location" {}
variable "admin_username" {}
variable "admin_password" {}
```

`outputs.tf`
```terraform
output "app-URL" {
  value = "http://${azurerm_public_ip.publicip.fqdn}:8000"
}
```

`hello.py`
```python
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


## Task 2: Write a unit test for your Terraform module

Install Go on your training workstation

```bash
 wget -c https://dl.google.com/go/go1.14.2.linux-amd64.tar.gz -O - | sudo tar -xz -C /usr/local
export PATH=$PATH:/usr/local/go/bin
```

```bash
go version
```

Create a new folder within the `~/workstation/terraform/testing_lab/modules/my_linux_vm` folder called `test`. This will house your test for the server module.

```shell
mkdir -p ~/workstation/terraform/testing_lab/modules/my_linux_vm/test
touch ~/workstation/terraform/testing_lab/modules/my_linux_vm/test/server_test.go
```

In the `test` folder, update the unit test in the `server_test.go` file.

`server_test.go`

```go
package test

import (
	"testing"
	"fmt"
	"net/http"
	"github.com/gruntwork-io/terratest/modules/shell"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

func TestEnvironment(t *testing.T) {
	t.Parallel()

	// Configuring the Terraform Options that we use to pass into terraform. We have an environment variables map to declare env variables. We also
	// configure the options with default retryable errors to handle the most common retryable errors encountered in
	// terraform testing.
	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		// The path to where our Terraform code is located
		TerraformDir: "../../../",
	})

	// defer is like a try finally, where at the end of this test, this line will always run. This line calls a Terraform destroy, which always gets called.
	defer terraform.Destroy(t, terraformOptions)

	// Run `terraform init` and `terraform apply`. The test fails if there are any errors
	terraform.InitAndApply(t, terraformOptions)

	server_dns := terraform.OutputList(t, terraformOptions, "public_dns")
	server_ip := terraform.OutputList(t, terraformOptions, "public_ip")
	
	//pings the server ips, will fail if they do not ping. The ping will wait for 60 seconds to ensure the ip is ready and can be pinged.
	
	for i := 0; i < len(server_ip); i++ {
		cmd := shell.Command{
			Command: "ping",
			Args:    []string{"-w", "180", "-c", "10", server_ip[i]},
		}
		shell.RunCommandAndGetOutput(t, cmd)
	}

	for i := 0; i < len(server_dns); i++ {
		//ensure that you can http get the servers and the response is 200
		resp, err := http.Get("http://" + server_dns[i])
		assert.Nil(t, err)
		defer resp.Body.Close()
		fmt.Print("HTTP request on " + server_dns[i] + " was ")
		fmt.Println(resp.StatusCode)
		assert.Equal(t, 200, resp.StatusCode)
	}

}
```

At the end of this task you should have a file layout similar to the following:

```shell
testing_lab
├── main.tf
├── modules
│   └── my_linux_vm
|          └── main.tf
|          └── variables.tf
|          └── outputs.tf
|          └── hello.py
│   	   └── test
│            └── server_test.go
├── terraform.tfvars
└── variables.tf
```

## Task 3:  Use Terratest to Deploy infrastructure
We will use Terratest to execute terraform to deploy our infrastructure into AWS.

```bash
cd /workstation/terraform/testing_lab/modules/my_linux_vm/test
test_file="$(ls *test.go)"
go mod init "${test_file%.*}"
go mod tidy
go test -v $test_file
```
**Note: Go tests have a default timeout of 10 minutes. If your infrastructure takes longer than 10 minutes to create, you may want to add the optional `-timeout` flag when running your go test. For a timeout of 30 minutes, you would do: `go test -v -timeout 30m $test_file`**

If working correctly, the test should output something along the lines of:

```
TestEnvironment 2021-08-19T14:49:55Z logger.go:66: Destroy complete! Resources: 7 destroyed.
TestEnvironment 2021-08-19T14:49:55Z logger.go:66: 
--- PASS: TestEnvironment (133.33s)
PASS
ok      command-line-arguments  133.336s
student@terraform-training-chipmunk:/workstation/terraform/test > 
```


## Task 4: Validate infrastructure with Terratest

Terratest allows us to validate that the infrastructure works correctly in that environment by making HTTP requests, API calls, SSH connections, etc.

For a full list of every function Terratest provides, visit their documentation [here](https://pkg.go.dev/github.com/gruntwork-io/terratest)

While Terratest has many built-in functions, you can also use other Go packages in conjunction with Terratest. For instance, you can create a Terraform configuration that creates an EC2 instance with specific tags. In conjunction with the AWS package in Go, you can connect to AWS and use the AWS Go package's functions to ensure the EC2 exists and has the specified tags in your configuration file.

Finally, you can have your test fail if something is not as it should be. With the "assert" package in Go, you can ensure your outputs are as expected, causing the test to fail if they are not.

## Task 5: Undeploy
The final step of our test is to undeploy everything at the end. Terratest allows us to perform a terraform destroy at the end of the testing cycle. Take a look inside of your `server_test.go` file. You should be able to find the following lines:

```go
	// defer is like a try finally, where at the end of this test, this line will always run. This line calls a Terraform destroy, which always gets called.
	defer terraform.Destroy(t, terraformOptions)
```

In Go, defer is a statement that will tell your test to run this command last no matter what. Even if the test fails, or errors out somewhere in the code during runtime, this terraform.Destroy line will always run to ensure your test infrastructure doesn't become unmanaged by Terraform and difficult to find.