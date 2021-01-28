# Terraform Enterprise - VCS Connection

## Expected Outcome

In this challenge, you will connect TFE to your personal github account.

## How to

### Create the VCS Connection

Login to github in one browser tab.

Login to TFE in another browser tab.

Within TFE, navigate to the settings page:

![](img/tfe-settings.png)

Click "VCS Providers" link:

![](img/tfe-settings-vcs.png)

Following the instructions on the documents page <https://www.terraform.io/docs/cloud/vcs/github.html>

The process involves several back and forth changes and is documented well in the link.

### Verify Connection

Navigate to <https://app.terraform.io> and click "+ New Workspace".

Click the VCS Connection in the "Source" section.

Verify you can see repositories:

![](img/tfe-vcs-verify.png)

If you can see repositories then you are good :+1:.

In the next lab you will create a repo and workspace.
