# Lab: Template Creation using Packer

Duration: 30 minutes

### Creating a Packer Image

To build an image packer utilizes a JSON file with the following sections...

##### [Builders](https://www.packer.io/docs/builders/index.html) (required)
* responsible for creating machines and generating images from them for various platforms.
* You can have multiple builder types in one file.

Below is an example of a basic builder for an AWS and GCP Image.
Create a new json file called `web-visitors.json` with the following builder.

```json
{
    "variables": {
      "azure_client_id": "{{ env `ARM_CLIENT_ID` }}",
      "azure_client_secret": "{{ env `ARM_CLIENT_SECRET` }}",
      "azure_subscription_id": "{{ env `ARM_SUBSCRIPTION_ID` }}",
      "azure_resource_group": "###-myrg"
    },
    "builders": [
      {
        "name": "azure_ubuntu",
        "type": "azure-arm",
        "client_id": "{{ user `azure_client_id` }}",
        "client_secret": "{{ user `azure_client_secret` }}",
        "subscription_id": "{{ user `azure_subscription_id` }}",
        "managed_image_resource_group_name": "{{ user `azure_resource_group` }}",
        "location": "East US",
        "image_publisher": "Canonical",
        "image_offer": "UbuntuServer",
        "image_sku": "18.04-LTS",
        "os_type": "Linux",
        "ssh_username": "packer",
        "managed_image_name": "hashistack-ubuntu-{{timestamp}}",
        "azure_tags": {
          "Product": "Hashistack",
          "App": "MyApp"
        }
      }
    ],
    "provisioners": [
      {
        "type": "shell",
        "inline": [
          "mkdir ~/src",
          "cd ~/src",
          "sudo apt-get -y install git",
          "git clone https://github.com/hashicorp/demo-terraform-101.git",
          "cp -R ~/src/demo-terraform-101/assets /tmp",
          "sudo sh /tmp/assets/setup-web.sh"
        ]
      }
    ]
  }
```

##### [Variables](https://www.packer.io/docs/templates/user-variables.html)
* User variables allow your templates to be further configured with variables from the command-line, environment variables, Vault, or files.
    * **Note**: these can be definied within the main JSON file and also be passed from an additional variable file, we will cover how to pass those variables further below
    
    
##### [Provisioners](https://www.packer.io/docs/provisioners/index.html)
* use builtin and third-party software to install and configure the machine image after booting. Provisioners prepare the system for use, so common use cases for provisioners include:
    * installing packages 
    * patching 
    * creating users 
    * downloading application code
    
   
##### Running Packer
Once the file is ready we will need to dothe following steps...

1. **packer validate web-vistors.json** - If properly formatted the file will successfully validate
    * This command will work just fine if all the variables are within the main packer file, but if you want to pass user variables from a different file the command will have an additional flag **packer validate web-vistors.json**

Validate your configuration.

```shell
> packer validate web-visitors.json
```

```shell
> packer build web-visitors.json
```
##### Resources
* Packer [Docs](https://www.packer.io/docs/index.html)
* Packer [CLI](https://www.packer.io/docs/commands/index.html)
