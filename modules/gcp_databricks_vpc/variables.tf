## ---------------------------------------------------------------------------------------------------------------------
## MODULE PARAMETERS
## These variables are expected to be passed in by the operator
## ---------------------------------------------------------------------------------------------------------------------

variable "DATABRICKS_ACCOUNT_ID" {
  type        = string
  description = "Databricks Account ID"
  sensitive   = true
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

variable "gcp_network_name" {
  type        = string
  description = "GCP VPC Network Name for Databricks Workspace"
  default     = "databricks-workspace-network"
}

variable "cidr_block" {
  type        = string
  description = "Virtual Internal IP Address Block Range"
  default     = "10.4.0.0/16"
}

variable "cidr_block_secondary_pods" {
  type        = string
  description = "Virtual Internal IP Secondary Address Block Range for K8 Pods"
  default     = "10.6.0.0/20"
}

variable "cidr_block_secondary_services" {
  type        = string
  description = "Virtual Internal IP Secondary Address Block Range K8 Services"
  default     = "10.8.0.0/20"
}