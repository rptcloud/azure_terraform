# Lab: Lab Setup

Duration: 10 minutes

- Task 1: Connect into your workstation
- Task 2: Create environment variables
- Task 3: Login with your Azure Service Principal Account 

## Task 1: Setup VS Code and SSH into your Workstation

Visual Studio Code, or VSCode, is a popular open source editor from Microsoft. Using an extension called Remote-SSH, you can connect to your workstation, edit files, and run commands all from within VSCode.

One way to navigate through this training is to use VSCode with a few added extensions. There are a few steps to install and configure VSCode, but once set up, this provides an easy to use environment.

- Download VSCode
- Download the Remote-SSH Extension
- Configure SSH
- Connection to your workstation in VSCode

### Task 2: Download VSCode to your local machine and configure extensions

1. Follow the instructions from [this site](https://code.visualstudio.com/download) to get the latest official download for your operating system.

1. Get familiar with the VSCode UI. The HashiCorp Configuration Language (HCL) is supported natively with VSCode.

### Task 3: Download the Remote-SSH Extension

1. Install an Remote-SSH extension for VS Code.

![Remote-SSH](./img/remote-ssh.png)

2. (Optional) Install the Open SSH compatible SSH client if one is not already present.
    - For Windows 10, follow [these instructions from Microsoft](https://docs.microsoft.com/en-us/windows-server/administration/openssh/openssh_install_firstuse).
      Note: PuTTY is not supported on Windows since the ssh command must be in the path.
    - For MacOS, OpenSSH should already be installed. Open a terminal window and run `ssh -V` to make sure.
  
3. SSH to your remote workstation with the Remote-SSH Extension using the credentials provided by the instructor.

## Task 4: Set your environment variables

Open a Terminal Session within VSCode to create a working directory for the Azure Lab.

Create a Working Directory for the Azure Lab

```bash
mkdir -p /workstation/terraform/azure && cd $_
code .
```

Set your Azure Service Principal account information by setting the following environment variables in the Terminal session of your VS Code window.  Your instructor will provide you with the vaules.

```bash
export ARM_CLIENT_ID="00000000-0000-0000-0000-000000000000"
export ARM_CLIENT_SECRET="00000000-0000-0000-0000-000000000000"
export ARM_SUBSCRIPTION_ID="00000000-0000-0000-0000-000000000000"
export ARM_TENANT_ID="00000000-0000-0000-0000-000000000000"
```

