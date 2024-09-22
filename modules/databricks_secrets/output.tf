output "databricks_secret_scope" {
  description = "Databricks Workspace Secret Scope"
  value       = module.databricks_secret_scope.databricks_secret_scope
}

output "databricks_secret_scope_id" {
  description = "Databricks Workspace Secret Scope ID"
  value       = module.databricks_secret_scope.databricks_secret_scope_id
}

output "gcp_secret_client_id_name" {
  description = "Google Secret Manager Client ID Secret Name"
  value       = module.gcp_secret_client_id.secret_name
}

output "gcp_secret_client_secret_name" {
  description = "Google Secret Manager Client Secret Secret Name"
  value       = module.gcp_secret_private_key_secret.secret_name
}

output "databricks_service_account_client_id_secret_name" {
  description = "Databricks Workspace GCP Client ID Secret Name"
  value       = module.databricks_service_account_key_name_secret.databricks_secret_name
}

output "databricks_service_account_private_key_id_secret_name" {
  description = "Databricks Workspace GCP Client Private Key ID Secret Name"
  value       = module.databricks_service_account_private_key_id_secret.databricks_secret_name
}

output "databricks_service_account_private_key_secret_name" {
  description = "Databricks Workspace GCP Client Private Key Secret Name"
  value       = module.databricks_service_account_private_key_secret.databricks_secret_name
}