terraform {
  required_providers {
    databricks = {
      source                = "databricks/databricks"
      configuration_aliases = [ databricks.workspace ]
    }
    google = {
      source  = "hashicorp/google"
      configuration_aliases = [ google.auth_session, ]
    }
  }
}

## ---------------------------------------------------------------------------------------------------------------------
## GCP SECRET CLIENT ID MODULE
##
## Deploys a GCP Secret Manager secret for the Databricks Service Principal Client ID.
##
## Parameters:
## - `secret_name`: The name of the secret.
## - `secret_data`: The secret data.
## ---------------------------------------------------------------------------------------------------------------------
module "gcp_secret_client_id" {
  source      = "../gcp_secret_manager"

  secret_name   = var.gcp_databricks_client_id_secret_name
  secret_data   = var.gcp_service_account_name

  providers = {
    google.auth_session = google.auth_session
  }
}


## ---------------------------------------------------------------------------------------------------------------------
## GCP PRIVATE KEY SECRET MODULE
##
## Deploys a GCP Secret Manager secret for the Databricks Service Principal private key ID.
##
## Parameters:
## - `secret_name`: The name of the secret.
## - `secret_data`: The secret data.
## ---------------------------------------------------------------------------------------------------------------------
module "gcp_secret_private_key_secret" {
  source      = "../gcp_secret_manager"

  secret_name   = var.gcp_databricks_client_private_key_id_secret_name
  secret_data   = jsonencode(var.gcp_service_account_private_key)

  providers = {
    google.auth_session = google.auth_session
  }
}


## ---------------------------------------------------------------------------------------------------------------------
## DATABRICKS SECRET SCOPE MODULE
## 
## This module creates a Databricks secret scope in a GCP Databricks workspace. 
## 
## Parameters:
## - `secret_scope`: Specifies the name of Databricks Secret Scope.
## ---------------------------------------------------------------------------------------------------------------------
module "databricks_secret_scope" {
  source = "github.com/sim-parables/terraform-databricks//modules/databricks_secret_scope?ref=ebaab7866a6be350d2c48246af64ad0b5332cde2"

  secret_scope = var.databricks_secret_scope_name

  providers = {
    databricks.workspace = databricks.workspace
  }
}


## ---------------------------------------------------------------------------------------------------------------------
## DATABRICKS SERVICE ACCOUNT KEY NAME SECRET MODULE
## 
## This module creates a secret in a Databricks secret scope. The secret stores the client ID 
## of an Azure service account
## 
## Parameters:
## - `secret_scope_id`: Specifies the secret scope ID where the secret will be stored
## - `secret_name`: Specifies the name of the secret
## - `secret_data`: Specifies the data of the secret (client ID of the GCP service account)
## ---------------------------------------------------------------------------------------------------------------------
module "databricks_service_account_key_name_secret" {
  source     = "github.com/sim-parables/terraform-databricks//modules/databricks_secret?ref=ebaab7866a6be350d2c48246af64ad0b5332cde2"
  depends_on = [ module.databricks_secret_scope ]

  secret_scope_id = module.databricks_secret_scope.databricks_secret_scope_id
  secret_name     = var.gcp_databricks_client_id_secret_name
  secret_data     = var.gcp_service_account_name

  providers = {
    databricks.workspace = databricks.workspace
  }
}


## ---------------------------------------------------------------------------------------------------------------------
## DATABRICKS SERVICE ACCOUNT PRIVATE KEY ID SECRET MODULE
## 
## This module creates a secret in a Databricks secret scope. The secret stores the client Secret 
## of an GCP service account.
## 
## Parameters:
## - `secret_scope_id`: Specifies the secret scope ID where the secret will be stored
## - `secret_name`: Specifies the name of the secret
## - `secret_data`: Specifies the data of the secret (private key ID of the GCP service account)
## ---------------------------------------------------------------------------------------------------------------------
module "databricks_service_account_private_key_id_secret" {
  source     = "github.com/sim-parables/terraform-databricks//modules/databricks_secret?ref=ebaab7866a6be350d2c48246af64ad0b5332cde2"
  depends_on = [ module.databricks_secret_scope ]

  secret_scope_id = module.databricks_secret_scope.databricks_secret_scope_id
  secret_name     = var.gcp_databricks_client_private_key_id_secret_name
  secret_data     = var.gcp_service_account_private_key.private_key_id

  providers = {
    databricks.workspace = databricks.workspace
  }
}


## ---------------------------------------------------------------------------------------------------------------------
## DATABRICKS SERVICE ACCOUNT PRIVATE KEY SECRET MODULE
## 
## This module creates a secret in a Databricks secret scope. The secret stores the client Secret 
## of an GCP service account.
## 
## Parameters:
## - `secret_scope_id`: Specifies the secret scope ID where the secret will be stored
## - `secret_name`: Specifies the name of the secret
## - `secret_data`: Specifies the data of the secret (private key of the GCP service account)
## ---------------------------------------------------------------------------------------------------------------------
module "databricks_service_account_private_key_secret" {
  source     = "github.com/sim-parables/terraform-databricks//modules/databricks_secret?ref=ebaab7866a6be350d2c48246af64ad0b5332cde2"
  depends_on = [ module.databricks_secret_scope ]

  secret_scope_id = module.databricks_secret_scope.databricks_secret_scope_id
  secret_name     = var.gcp_databricks_client_private_key_secret_name
  secret_data     = var.gcp_service_account_private_key.private_key

  providers = {
    databricks.workspace = databricks.workspace
  }
}
