output "databricks_workspace_host" {
  description = "Databricks Workspace Host URL"
  value       = module.databricks_workspace.databricks_host
}

output "databricks_access_token" {
  description = "Databricks Personal Access Token"
  value       = module.databricks_workspace.databricks_token
  sensitive   = true
}

output "databricks_workspace_id" {
  description = "Databricks Workspace ID (Number Only)"
  value       = module.databricks_workspace.databricks_workspace_id
}

output "service_account" {
  description = "GCP Blob Trigger Architecture Service Account"
  value       = module.service_account_auth.service_account_email
  sensitive   = true
}

output "service_account_access_token" {
  description = "Service Account Access Token"
  value       = module.service_account_auth.access_token
  sensitive   = true
}

output "google_workload_identity_provider" {
  description = "GCP Workload Identity Federation Provider Resource ID"
  value       = module.workload_identity_federation_principals.workload_identity_provider_id
}

output "google_secret_client_id_name" {
  description = "GCP Secret Manager Client ID Secret Name"
  value       = module.databricks_secrets.gcp_secret_client_id_name
}

output "google_secret_client_secret_name" {
  description = "GCP Secret Manager Client Secret Secret Name"
  value       = module.databricks_secrets.gcp_secret_client_secret_name
}

output "databricks_secret_scope" {
  description = "Databricks Workspace Secret Scope"
  value       = module.databricks_secrets.databricks_secret_scope
}

output "databricks_service_account_client_id_secret_name" {
  description = "Databricks Workspace GCP Client ID Secret Name"
  value       = module.databricks_secrets.databricks_service_account_client_id_secret_name
}

output "databricks_service_account_private_key_id_secret_name" {
  description = "Databricks Workspace GCP Client Private Key ID Secret Name"
  value       = module.databricks_secrets.databricks_service_account_private_key_id_secret_name
}

output "databricks_service_account_private_key_secret_name" {
  description = "Databricks Workspace GCP Client Private Key Secret Name"
  value       = module.databricks_secrets.databricks_service_account_private_key_secret_name
}

output "databricks_external_location_url" {
  description = "Databricks GCP Metastore Bucket GCS URL"
  value       = module.databricks_metastore.databricks_external_location_url
}

output "databricks_cluster_ids" {
  description = "List of Databricks Workspace Cluster IDs"
  value       = module.databricks_workspace_config.databricks_cluster_ids
}

output "databricks_example_holdings_data_path" {
  description = "Databricks Example Holding Data Unity Catalog File Path"
  value       = module.databricks_workspace_config.databricks_example_holdings_data_path
}

output "databricks_example_weather_data_path" {
  description = "Databricks Example Weather Data Unity Catalog File Path"
  value       = module.databricks_workspace_config.databricks_example_weather_data_path
}

output "databricks_unity_catalog_table_paths" {
  description = "Databricks Unity Catalog Table Paths"
  value       = module.databricks_workspace_config.databricks_unity_catalog_table_paths
}