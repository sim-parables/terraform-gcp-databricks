## ---------------------------------------------------------------------------------------------------------------------
## MODULE PARAMETERS
## These variables are expected to be passed in by the operator
## ---------------------------------------------------------------------------------------------------------------------

variable "gcp_service_account_name" {
  type        = string
  description = "GCP Service Account Name which is Authorized for Databricks"
}

variable "gcp_service_account_private_key" {
  description = "GCP Service Account Private Key which is Authorized for Databricks"
  sensitive   = true
  type        = object({
    client_email = string
    private_key_id = string
    private_key    = string
  })
}

## ---------------------------------------------------------------------------------------------------------------------
## OPTIONAL PARAMETERS
## These variables have defaults and may be overridden
## ---------------------------------------------------------------------------------------------------------------------

variable "gcp_databricks_client_id_secret_name" {
  type        = string
  description = "GCP IAM Client ID Databricks Secret Name for Databricks Service Principal"
  default     = "databricks-sp-client-id"
}

variable "gcp_databricks_client_private_key_id_secret_name" {
  type        = string
  description = "GCP IAM Service Account Private Key ID Databricks Secret Name for Databricks Service Principal"
  default     = "databricks-sp-private-key-id"
}

variable "gcp_databricks_client_private_key_secret_name" {
  type        = string
  description = "GCP IAM Service Account Private Key Databricks Secret Name for Databricks Service Principal"
  default     = "databricks-sp-private-key"
}

variable "databricks_secret_scope_name" {
  type        = string
  description = "Databricks Workspace Secret Scope Name"
  default     = "example-secret"
}