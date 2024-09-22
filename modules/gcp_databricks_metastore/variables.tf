## ---------------------------------------------------------------------------------------------------------------------
## MODULE PARAMETERS
## These variables are expected to be passed in by the operator
## ---------------------------------------------------------------------------------------------------------------------

variable "DATABRICKS_ADMINISTRATOR" {
  type        = string
  description = "Email Adress for the Databricks Unity Catalog Administrator"
}

variable "databricks_workspace_number" {
  type        = number
  description = "Databricks Workspace ID (Number Only)"
}

variable "databricks_storage_name" {
  type        = string
  description = "Databricks Workspace Storage Name"
}

variable "databricks_metastore_grants" {
  description = "List of Databricks Metastore Grant Mappings"
  type        = list(string)
}

variable "databricks_catalog_grants" {
  description = "List of Databricks Unity Catalog Grant Mappings"
  type        = list(string)
}

variable "gcp_region" {
  type        = string
  description = "GCP Region"
}


## ---------------------------------------------------------------------------------------------------------------------
## OPTIONAL PARAMETERS
## These variables have defaults and may be overridden
## ---------------------------------------------------------------------------------------------------------------------

variable "databricks_service_principal_name" {
  type        = string
  description = "Databricks Service Principal Name"
  default     = "databricks-service-principal"
}

variable "databricks_service_principal_token_seconds" {
  type        = number
  description = "Databricks Service Principal Token Lifetime in Seconds"
  default     = 3600
}

variable "databricks_catalog_name" {
  type        = string
  description = "Databricks Catalog Name"
  default     = "sandbox"
}

variable "databricks_group_prefix" {
  type        = string
  description = "Databricks Accounts and Workspace Group Name Prefix"
  default     = "example-group"
}
