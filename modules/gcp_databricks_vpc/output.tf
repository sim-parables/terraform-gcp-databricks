output "network_id" {
  description = "GCP VPC Databricks Network ID"
  value       = databricks_mws_networks.this.network_id
}

output "subnet_region" {
  description = "GCP VPC Subnet Region"
  value       = google_compute_subnetwork.this.region
}