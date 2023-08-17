# Operating Terraform Cloud for Teams

Terraform Cloud includes Teams and permissions that are set at the organization and workspace level. In this challenge, you will create teams in your TFC organization, add users, and assign teams permissions to workspaces.

You will need to upgrade to the Standard tier of TFC, which requires an HCP account. It comes with $50 in free credit. You can sign up for an HCP account [here](https://portal.cloud.hashicorp.com/signup).

## Tasks

- Create teams with permissions
- Add users to teams and test permissions
- Assign teams to workspaces with permissions

## Create teams with permissions

Teams can have different levels of access to your workspaces. You can invite other users to collaborate on code changes, approvals, and Terraform runs.

1. Go into your organization's General Settings and click on the **Teams** link.
2. Add a team called **org_admins**. Admins should be able to perform all organization-level actions.
3. Add another team called **web_app_devs**. Developers should not have any organization-wide access.
4. Add a third team called **managers**. Managers should also not have any organization-wide access.

## Add users to teams and test permissions

Now that you have created teams you can invite some users to your organization. Return to your **General Settings** for the organization, and select **Users**. Then click the "Invite a user" button.

Invite a new user with an email you have access to and assign them to the org_admins group. You can also make up a fictitious email, although you won't be able to test permissions.

If you are using Gmail or Exchange, you can create an email address that follows the format `your_email+tfc@gmail.com`. This will allow you to create a new email address that will be delivered to your inbox, but will be unique to TFC.

For example, if your Gmail address is `john.smith@gmail.com`, you can use the address `john.smith+tfc@gmail.com` for your new user.

## Assign teams to workspaces with permissions

Next, assign access rights to the an existing workspace. Go into the **Team Access** page of the workspace settings. If you don't see the Team Access link you might need to log out and back into Terraform Cloud.

You'll want to click the "Add team and permissions" button and then click the "Select team" button next to each team to which you wish to grant workspace access. Then click the "Assign permissions" button for the desired permission.

- Give the **web_app_devs** group plan level access.
- Give the **managers** group read level access.
