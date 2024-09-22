output "secret_name" {
  description = "Google Secret Manager Secret Name"
  value       = var.secret_name
}

output "secret_id" {
  description = "Google Secret Manager Secret ID"
  value       = google_secret_manager_secret.this.id
}