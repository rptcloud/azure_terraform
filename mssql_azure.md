## Create MSSQL DB in Azure

### Utilize a Public Module to create a MSSQL Database in Azure

Be sure to update the `###` for the `sqlserver_name` with your initials 

`main.tf`

```hcl
# Azurerm provider configuration
provider "azurerm" {
  features {}
}

# data "azurerm_log_analytics_workspace" "example" {
#   name                = "loganalytics-we-sharedtest2"
#   resource_group_name = "rg-shared-westeurope-01"
# }

module "mssql-server" {
  source  = "kumarvna/mssql-db/azurerm"
  version = "1.3.0"

  # By default, this module will create a resource group
  # proivde a name to use an existing resource group and set the argument 
  # to `create_resource_group = false` if you want to existing resoruce group. 
  # If you use existing resrouce group location will be the same as existing RG.
  create_resource_group = true
  resource_group_name   = "rg-db-01"
  location              = "eastus"

  # SQL Server and Database details
  # The valid service objective name for the database include S0, S1, S2, S3, P1, P2, P4, P6, P11 
  sqlserver_name               = "###-sqldbserver01"
  database_name                = "demomssqldb"
  sql_database_edition         = "Standard"
  sqldb_service_objective_name = "S1"

  # SQL server extended auditing policy defaults to `true`. 
  # To turn off set enable_sql_server_extended_auditing_policy to `false`  
  # DB extended auditing policy defaults to `false`. 
  # to tun on set the variable `enable_database_extended_auditing_policy` to `true` 
  # To enable Azure Defender for database set `enable_threat_detection_policy` to true 
  enable_threat_detection_policy = true
  log_retention_days             = 30

  # schedule scan notifications to the subscription administrators
  # Manage Vulnerability Assessment set `enable_vulnerability_assessment` to `true`
  enable_vulnerability_assessment = false
  email_addresses_for_alerts      = ["user@example.com", "firstname.lastname@example.com"]

  # AD administrator for an Azure SQL server
  # Allows you to set a user or group as the AD administrator for an Azure SQL server
  ad_admin_login_name = "firstname.lastname@example.com"

  # (Optional) To enable Azure Monitoring for Azure SQL database including audit logs
  # Log Analytic workspace resource id required
  # (Optional) Specify `storage_account_id` to save monitoring logs to storage. 
  # enable_log_monitoring      = true
  # log_analytics_workspace_id = data.azurerm_log_analytics_workspace.example.id

  # Firewall Rules to allow azure and external clients and specific Ip address/ranges. 
  enable_firewall_rules = true
  firewall_rules = [
    {
      name             = "access-to-azure"
      start_ip_address = "0.0.0.0"
      end_ip_address   = "0.0.0.0"
    },
    {
      name             = "workstation-ip"
      start_ip_address = "3.239.33.159"
      end_ip_address   = "3.239.33.159"
    }
  ]

  # Adding additional TAG's to your Azure resources
  tags = {
    ProjectName  = "demo-project"
    Env          = "dev"
    Owner        = "user@example.com"
    BusinessUnit = "CORP"
    ServiceClass = "Gold"
  }
}
```

Replace the `start_ip_address` and `end_ip_address` above to the IP of your workstation.  This can be obtained by running:

```shell
curl ifconfig.me
```

`outputs.tf`

```hcl
output "sql_server_fqdn" {
  value = module.mssql-server.primary_sql_server_fqdn
}

output "sql_admin_user" {
  value = module.mssql-server.sql_server_admin_user
  sensitive = true
}

output "sql_admin_password" {
  value = module.mssql-server.sql_server_admin_password
  sensitive = true
}

output "sql_database_name" {
  value = module.mssql-server.sql_database_name
}

output "sql_database_location" {
  value = module.mssql-server.resource_group_location
}
```

### Connect to the database using the Server FQDN, Database Name, User and Password
