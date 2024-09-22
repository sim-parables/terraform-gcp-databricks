terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      configuration_aliases = [ google.auth_session ]
    }
  }
}


## ---------------------------------------------------------------------------------------------------------------------
## GOOGLE CLIENT CONFIG DATA SOURCE
## 
## GCP Client Configurations/Details Data Source.
## ---------------------------------------------------------------------------------------------------------------------
data "google_client_config" "this" {
  provider = google.auth_session
}


## ---------------------------------------------------------------------------------------------------------------------
## GOOGLE SECRET MANAGER SECRET RESOURCE
##
## This resource creates a secret in Google Secret Manager.
##
## Parameters:
## - `secret_id`: The ID of the secret.
## ---------------------------------------------------------------------------------------------------------------------
resource "google_secret_manager_secret" "this" {
  provider  = google.auth_session
  secret_id = var.secret_name

  replication {
    user_managed {
      replicas {
        location = data.google_client_config.this.region
      }
    }
  }
}



## ---------------------------------------------------------------------------------------------------------------------
## GOOGLE SECRET MANAGER SECRET VERSION RESOURCE
##
## This resource creates a version of a secret in Google Secret Manager.
##
## Parameters:
## - `secret`: The ID of the secret to associate this version with.
## - `secret_data`: The secret data to store.
## ---------------------------------------------------------------------------------------------------------------------
resource "google_secret_manager_secret_version" "this" {
  provider    = google.auth_session
  secret      = google_secret_manager_secret.this.id
  secret_data = var.secret_data
}
