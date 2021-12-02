# Lab: API Workflow

The Terraform Cloud REST API can be used to automate interactions with Terraform Cloud using the API-driven workflow. The API-driven workflow can be used by operations teams within CI/CD tools and pipelines such as Jenkins, etc.

Duration: 20 minutes

- Task 1: Clone the terraform-guides repository
- Task 2: Update the automation-script to call python3
- Task 3: Set the appropriate enviornment variables
- Task 4: Run the automation script
- Task 5: Validate the corresponding API calls to Terraform Cloud.
- Task 6: Update the Terraform code version of your Workspace
- Task 7: Review Workspace API
- Task 8: Delete the Workspace via API

## Task 1: Clone the terraform-guides repository

The [terraform-guides](https://github.com/hashicorp/terraform-guides) repository contains sample Terraform configurations, Sentinel policies, and automation scripts that can be used with Terraform Enterprise.

Clone the terraform-guides repo and change to the `automation-script` directory

```
cd /workstation/terraform
git clone https://github.com/hashicorp/terraform-guides.git
cd ./terraform-guides/operations/automation-script
```

This directory contains several scripts that utlize the Terraform Cloud API to showcase automation interactions with Terraform cloud. The `loadandRunWorkspace-python.sh` script clones a git repository, creates a workspace (if it does not already exist), uploads a Terraform configuration to it, sets variables in it, triggers a run, checks the results of Sentinel policy checks, and even does an apply against the workspace if permitted. If an apply is done, the script waits for it to finish and then downloads the apply log and the before and after state files. If an apply cannot be done, it downloads the plan log instead.

## Task 2: Update the automation-script to call python3

Edit the `loadAndRunWorkspace-python.sh` replacing `python` with `python3` as that is what is installe on the training worksations.

## Task 3: Set the appropriate enviornment variables

1. Generate a [team token](https://www.terraform.io/docs/enterprise/users-teams-organizations/service-accounts.html#team-service-accounts) for the owners team in your organization in the Terraform Enterprise UI by selecting your organization settings, then Teams, then owners, and then clicking the Generate button and saving the token that is displayed.
2. `export TFE_TOKEN=<owners_token>` where \<owners_token\> is the token generated in the previous step.
3. `export TFE_ORG=<your_organization>` where \<your_organization\> is the name of your target TFE organization.
4. `export TFE_ADDR=<your_address>` where \<your_address\> is the custom address of your target TFC server in the format server.domain.tld. If you do not set this environment variable it will default to the Terraform Enterprise Cloud/SaaS address of app.terraform.io.

## Task 4: Run the automation script

1. Run `./loadAndRunWorkspace-python.sh` or `./loadAndRunWorkspace-python.sh "" "" <override>` where \<override\> is "yes" or "no". (The empty quotes are needed in the second case so that override is the third variable.) If you do not specify a value for \<override\>, the script will set it to "no".
2. If you want to specify a workspace name in your command, run `./loadAndRunWorkspace-python.sh "" <workspace>` where \<workspace\> is the name of the workspace.

## Task 5: Validate the corresponding API calls to Terraform Cloud.

Validate that the automation script creates a workspace, performs an Terraform run and outputs the terraform plan summary. Open up the `run.log` to review the items executed by the series of TFC API calls performed by the script.

## Task 6: Update the Terraform code version of your Workspace

1. Update the `"terraform-version": "1.0.5"` within the shell script to a new terraform version. This version is saved by the script to a `workspace.template.json` file which is used to generate a `workspace.json` payload used by Terraform Cloud API syntax.

2. Run `./loadAndRunWorkspace-python.sh "" myWorkspace` to create a new workspace with the updated terraform version.

## Task 7: Review Workspace API

Execute an API call to return the workspaces details for any given workspace:

```
curl -s --header "Authorization: Bearer $TFE_TOKEN" --header "Content-Type: application/vnd.api+json" "https://app.terraform.io/api/v2/organizations/$TFE_ORG/workspaces/workspace-from-api" | jq
```

## Task 8: Delete the Workspace via API

1. Run `./deleteWorkspace.sh` to delete the workspace created via API.


## Reference

- For full documentation on this script refer to the script [README.md](https://github.com/hashicorp/terraform-guides/blob/master/operations/automation-script/README.md)
- [Terraform Cloud API Documentation](https://www.terraform.io/docs/cloud/api/index.html)
