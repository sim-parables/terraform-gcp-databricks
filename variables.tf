## ---------------------------------------------------------------------------------------------------------------------
## MODULE PARAMETERS
## These variables are expected to be passed in by the operator
## ---------------------------------------------------------------------------------------------------------------------

variable "DATABRICKS_ACCOUNT_ID" {
  type        = string
  description = "Databricks Account ID"
  sensitive   = true
}

variable "databricks_workspace_name" {
  type        = string
  description = "Databricks Workspace Name"
}

variable "gcp_project_id" {
  type        = string
  description = "GCP Project ID"
}

variable "gcp_region" {
  type        = string
  description = "GCP Region"
}

## ---------------------------------------------------------------------------------------------------------------------
## OPTIONAL PARAMETERS
## These variables have defaults and may be overridden
## ---------------------------------------------------------------------------------------------------------------------

variable "gcp_databricks_ip_range" {
  type        = string
  description = "GCP GKE Workspace Node IP Range for Databricks"
  default     = "10.3.0.0/28"
}

variable "gcp_databricks_connectivity_type" {
  type        = string
  description = "GCP GKE Workspace Node Connectivity Type for Databricks"
  default     = "PRIVATE_NODE_PUBLIC_MASTER"
}

variable "gcp_databricks_service_account_role" {
  type        = string
  description = "Databricks Generated GCP Service Account Custom Workspace IAM Role Name"
  default     = "gcp-workspace-role"
}