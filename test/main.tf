terraform {
  required_providers {
    google = {
      source = "hashicorp/google"
    }

    databricks = {
      source = "databricks/databricks"
    }
  }

  backend "remote" {
    # The name of your Terraform Cloud organization.
    organization = "sim-parables"

    # The name of the Terraform Cloud workspace to store Terraform state files in.
    workspaces {
      name = "ci-cd-gcp-workspace"
    }
  }
}

## ---------------------------------------------------------------------------------------------------------------------
## RANDOM STRING RESOURCE
##
## This resource generates a random string of a specified length.
##
## Parameters:
## - `special`: Whether to include special characters in the random string.
## - `upper`: Whether to include uppercase letters in the random string.
## - `length`: The length of the random string.
## ---------------------------------------------------------------------------------------------------------------------
resource "random_string" "this" {
  special = false
  upper   = false
  length  = 4
}

locals {
  cloud   = "gcp"
  program = "spark-databricks"
  project = "datasim"
}

locals  {
  prefix             = "${local.program}-${local.project}-${random_string.this.id}"
  secret_scope       = upper(local.cloud)
  client_id_name     = "${local.prefix}-sp-client-id"
  client_secret_name = "${local.prefix}-sp-client-secret"
  catalog_name       = "${local.project}_catalog"
  schema_name        = "db_terraform"

  principal_roles = [
    {
      principal = "principal://iam.googleapis.com/projects/${data.google_project.this.number}/locations/global/workloadIdentityPools/${var.POOL_ID}/subject/repo:${var.GITHUB_REPOSITORY}:ref:${var.GITHUB_REF}",
      role      = "roles/iam.workloadIdentityUser"
    },
    {
      principal = "principal://iam.googleapis.com/projects/${data.google_project.this.number}/locations/global/workloadIdentityPools/${var.POOL_ID}/subject/repo:${var.GITHUB_REPOSITORY}:environment:${var.GITHUB_ENV}",
      role      = "roles/iam.workloadIdentityUser"
    },
  ]

  databricks_metastore_grants = [
    "CREATE_CATALOG", "CREATE_CONNECTION", "CREATE_EXTERNAL_LOCATION",
    "CREATE_STORAGE_CREDENTIAL",
  ]

  databricks_catalog_grants = [
    "CREATE_SCHEMA", "CREATE_FUNCTION", "CREATE_TABLE", "CREATE_VOLUME",
    "USE_CATALOG", "USE_SCHEMA", "READ_VOLUME", "SELECT",
  ]

  # Define Spark environment variables
  spark_env_variables = {
    "CLOUD_PROVIDER" : upper(local.cloud),
    "RAW_DIR" : module.databricks_metastore.databricks_external_location_url,
    "OUTPUT_DIR" : module.databricks_metastore.databricks_external_location_url,
    "SERVICE_ACCOUNT_CLIENT_ID" : module.databricks_secrets.gcp_secret_client_id_name,
    "SERVICE_ACCOUNT_CLIENT_SECRET" : module.databricks_secrets.gcp_secret_client_secret_name,
    "GOOGLE_PROJECT_ID": data.google_project.this.project_id,
    "GOOGLE_PROJECT_NUMBER": data.google_project.this.number
  }

  spark_conf_variables = {
    "fs.gs.auth.type" : "USER_CREDENTIALS",
    "fs.gs.impl": "com.google.cloud.hadoop.fs.gcs.GoogleHadoopFileSystem",
    "fs.gs.project.id": data.google_project.this.project_id,
    "fs.AbstractFileSystem.gs.impl": "com.google.cloud.hadoop.fs.gcs.GoogleHadoopFS",
    "google.cloud.auth.service.account.enable": "true",
    "google.cloud.auth.service.account.email": module.service_account_auth.service_account_email,
    "google.cloud.auth.service.account.private.key.id" : "{{secrets/${module.databricks_secrets.databricks_secret_scope_id}/${module.databricks_secrets.databricks_service_account_private_key_id_secret_name}}}",
    "google.cloud.auth.service.account.private.key" : "{{secrets/${module.databricks_secrets.databricks_secret_scope_id}/${module.databricks_secrets.databricks_service_account_private_key_secret_name}}}"
  }

  databricks_cluster_library_files = [
    {
      file_name      = "gcs-connector-hadoop3-2.2.17-shaded.jar"
      content_base64 = data.http.gcs_connector_hadoop.response_body_base64
    },
  ]
}

## ---------------------------------------------------------------------------------------------------------------------
## GOOGLE PROJECT DATA SOURCE
## 
## GCP Project Configurations/Details Data Source.
## ---------------------------------------------------------------------------------------------------------------------
data "google_project" "this" {
  provider = google.tokengen
}


## ---------------------------------------------------------------------------------------------------------------------
## GOOGLE CLIENT CONFIG DATA SOURCE
## 
## GCP Client Configurations/Details Data Source.
## ---------------------------------------------------------------------------------------------------------------------
data "google_client_config" "this" {
  provider = google.tokengen
}


## ---------------------------------------------------------------------------------------------------------------------
## GCP PROVIDER
##
## Configures the GCP provider with OIDC Connect via ENV Variables.
## ---------------------------------------------------------------------------------------------------------------------
provider "google" {
  alias = "tokengen"
}


##---------------------------------------------------------------------------------------------------------------------
## GCP SERVICE ACCOUNT MODULE
##
## This module provisions a GCP service account along with associated roles and security groups.
##
## Parameters:
## - `IMPERSONATE_SERVICE_ACCOUNT_EMAIL`: Existing GCP service account email to impersonate for new SA creation.
## - `new_service_account_name`: New service account name.
## - `roles_list`: List of IAM roles to bind to service account.
##---------------------------------------------------------------------------------------------------------------------
module "service_account_auth" {
  source = "github.com/sim-parables/terraform-gcp-service-account.git?ref=5645d79241069640d425010dbf0cf11785a03da7"

  IMPERSONATE_SERVICE_ACCOUNT_EMAIL = var.IMPERSONATE_SERVICE_ACCOUNT_EMAIL
  new_service_account_name          = "serviceaccount-${random_string.this.id}"
  
  roles_list = [
    "roles/iam.serviceAccountAdmin",
    "roles/iam.serviceAccountKeyAdmin",
    "roles/iam.roleAdmin",
    "roles/resourcemanager.projectIamAdmin",
    "roles/serviceusage.serviceUsageConsumer",
    "roles/compute.networkAdmin",
    "roles/compute.storageAdmin",
    "roles/container.admin",
    "roles/storage.objectAdmin",
    "roles/storage.admin",
    "roles/secretmanager.admin",
  ]

  providers = {
    google.tokengen = google.tokengen
  }
}


## ---------------------------------------------------------------------------------------------------------------------
## GCP PROVIDER
##
## Authenticated session with newly created service account.
##
## Parameters:
## - `access_token`: Access token from service_account_auth module
## ---------------------------------------------------------------------------------------------------------------------
provider "google" {
  alias        = "auth_session"
  access_token = module.service_account_auth.access_token
  project      = data.google_project.this.project_id
}


## ---------------------------------------------------------------------------------------------------------------------
## GOOGLE PROJECT IAM CUSTOM ROLE RESOURCE
##
## Create a custom Databricks Workspace Role for Databricks MWS Workspace creation, and service management, which
## binds to the newly created service account. More details can be found here:
## https://docs.gcp.databricks.com/en/admin/cloud-configurations/gcp/permissions.html
##
## Parameters:
## - `role_id`: Unique name for the customer IAM role.
## - `title`: Display name for the customer IAM role.
## - `permissions`: List of custom IAM role permissions for custom role.
## ---------------------------------------------------------------------------------------------------------------------
resource "google_project_iam_custom_role" "this" {
  provider = google.auth_session
  depends_on = [ module.service_account_auth ]
  
  role_id     = replace("${local.prefix}-creator-role", "-", "_")
  title       = "Databricks Workspace Creator"
  permissions = [
    # Customer Workplace Creator Roles
    "iam.serviceAccounts.getIamPolicy",
    "iam.serviceAccounts.setIamPolicy",
    "iam.roles.create",
    "iam.roles.delete",
    "iam.roles.get",
    "iam.roles.update",
    "resourcemanager.projects.get",
    "resourcemanager.projects.getIamPolicy",
    "resourcemanager.projects.setIamPolicy",
    "serviceusage.services.get",
    "serviceusage.services.list",
    "serviceusage.services.enable",
    "compute.networks.get",
    "compute.projects.get",
    "compute.subnetworks.get",
    "compute.forwardingRules.get",
    "compute.forwardingRules.list",
  ]
}


## ---------------------------------------------------------------------------------------------------------------------
## GOOGLE PROJECT IAM BINDING RESOURCE
##
## Bind the custom Databricks Workspace role to GCP Project members.
##
## Parameters:
## - `project`: GCP Project ID.
## - `role`: Customer IAM role ID.
## - `members`: List of GCP Project members.
## ---------------------------------------------------------------------------------------------------------------------
resource "google_project_iam_binding" "this" {
  provider = google.auth_session
  depends_on = [ google_project_iam_custom_role.this ]

  project = data.google_project.this.project_id
  role    = google_project_iam_custom_role.this.id
  members = [
    module.service_account_auth.service_account_member,
    var.DATABRICKS_ACCOUNT_GOOGLE_MEMBER
  ]
}


## ---------------------------------------------------------------------------------------------------------------------
## GOOGLE SERVICE ACCOUNT KEY RESOURCE
##
## Create a Googe service account JSON Private Access Key for Databricks Workspace Spark authentication.
##
## Parameters:
## - `service_account_id`: New service account ID.
## - `public_key_type`: Service account public key file output type.
## - `private_key_type`: Service account private key file output type.
## - `valid_after`: Timestamp indicating when the key can be used.
## - `valid_before`: Timestamp indicating when the key will expire.
## ---------------------------------------------------------------------------------------------------------------------
resource "google_service_account_key" "this"{
  provider = google.auth_session
  depends_on = [ google_project_iam_binding.this ]

  service_account_id = module.service_account_auth.service_account_id
  public_key_type    = "TYPE_X509_PEM_FILE"
  private_key_type   = "TYPE_GOOGLE_CREDENTIALS_FILE"
  #valid_after        = plantimestamp()
  #valid_before       = timeadd(plantimestamp(), "1h")
}


##---------------------------------------------------------------------------------------------------------------------
## GCP WORKLOAD IDENTITY FEDERTAION PRINICPALS MODULE
##
## This module creates Service Account grants to a specific Google Workload Identity Federation (WIF) Pool
## to allow OpenID Connect authorization within Github Actions.
##
## Parameters:
## - `project_number`: GCP project number (not ID).
## - `pool_id`: Exiting Google WIF pool ID.
## - `prinicpal_roles`: List of objects defining WIF prinicpals and impersonating roles.
## - `service_account_id`: New service account ID.
##---------------------------------------------------------------------------------------------------------------------
module "workload_identity_federation_principals" {
  source = "github.com/sim-parables/terraform-gcp-service-account.git?ref=5645d79241069640d425010dbf0cf11785a03da7//modules/workflow_identity_federation_principal"
  depends_on = [ module.service_account_auth ]

  project_number     = data.google_project.this.number
  pool_id            = var.POOL_ID
  provider_id        = var.PROVIDER_ID
  principal_roles    = local.principal_roles
  service_account_id = module.service_account_auth.service_account_id

  providers = {
    google.auth_session = google.auth_session
  }
}


## ---------------------------------------------------------------------------------------------------------------------
## DATABRICKS PROVIDER
##
## This provider configures Databricks with the necessary authentication details.
##
## Parameters:
## - `alias`: An alias for the provider.
## - `profile`: The Databricks account CLI Profile name.
## ---------------------------------------------------------------------------------------------------------------------
provider "databricks" {
  alias   = "accounts"
  profile = var.DATABRICKS_CLI_PROFILE
}


## ---------------------------------------------------------------------------------------------------------------------
## DATABRICKS GCP WORKSPACE MODULE
##
## This module sets up a Databricks workspace on Google Cloud Platform (GCP).
##
## Parameters:
## - `DATABRICKS_ACCOUNT_ID`: The ID of the Databricks account.
## - `databricks_workspace_name`: Name to apply to Databricks Workspace.
## - `gcp_project_id`: GCP project ID.
## - `gcp_region`: GCP region.
## - `gcp_databricks_service_account_role`: GCP generated service account custom Databricks Workspace role name.
## ---------------------------------------------------------------------------------------------------------------------
module "databricks_workspace" {
  source     = "../"
  depends_on = [ google_project_iam_binding.this ]
  
  DATABRICKS_ACCOUNT_ID               = var.DATABRICKS_ACCOUNT_ID
  databricks_workspace_name           = "${local.prefix}-workspace"
  gcp_project_id                      = data.google_project.this.project_id
  gcp_region                          = data.google_client_config.this.region
  gcp_databricks_service_account_role = "${local.prefix}-service-role"

  providers = {
    google.auth_session = google.auth_session
    databricks.accounts = databricks.accounts
  }
}


## ---------------------------------------------------------------------------------------------------------------------
## DATABRICKS PROVIDER
##
## Configures the Databricks Workspace provider.
##
## Parameters:
## - `alias`: Provdier Alias to Databricks Accounts
## - `host`: The Databricks Workspace Host URL.
## - `token`: The Databricks Workspace Personal Access Token.
## ---------------------------------------------------------------------------------------------------------------------
provider "databricks" {
  alias = "workspace"
  host  = module.databricks_workspace.databricks_host
  token = module.databricks_workspace.databricks_token
}


## ---------------------------------------------------------------------------------------------------------------------
## DATABRICKS SECRETS MODULE
##
## Configure Databricks Secrets for both workspace and GCP Secret Manager.
##
## Parameters:
## - `gcp_service_account_name`: GCP IAM service account name.
## - `gcp_service_account_secret`: GCP IAM service account secret.
## ---------------------------------------------------------------------------------------------------------------------
module "databricks_secrets" {
  source     = "../modules/databricks_secrets"
  depends_on = [ module.databricks_workspace ]

  gcp_service_account_name   = module.service_account_auth.service_account_email
  gcp_service_account_private_key = jsondecode(base64decode(google_service_account_key.this.private_key))

  providers = {
    google.auth_session     = google.auth_session
    databricks.workspace    = databricks.workspace
  }
}


## ---------------------------------------------------------------------------------------------------------------------
## DATABRICKS METASTORE MODULE
##
## This module creates Databricks metastores and assigns them to Databricks Workspaces for Unity Catalog.
##
## Parameters:
## - `DATABRICKS_ADMINISTRATOR`: The Databricks Account & Workspace administrator email.
## - `databricks_storage_name`: Databricks Storage Credential Name.
## - `databricks_workspace_number`: Databricks workspace number.
## - `databricks_group_prefix`: The prefix for Databricks metastore group names.
## - `databricks_metastore_grants`: List of Databricks Metastore specific grants to apply to admin group.
## - `databricks_catalog_grants`: List of Databricks Catalog specific grants to apply to admin group.
## - `databricks_catalog_name`: Name of catalog to create in Databricks Workspace.
## ---------------------------------------------------------------------------------------------------------------------
module "databricks_metastore" {
  source     = "../modules/gcp_databricks_metastore"
  depends_on = [ module.databricks_workspace ]

  DATABRICKS_ADMINISTRATOR          = var.DATABRICKS_ADMINISTRATOR
  databricks_service_principal_name = "${local.prefix}-service-principal"
  databricks_storage_name           = "${local.prefix}-catalog-bucket"
  databricks_workspace_number       = module.databricks_workspace.databricks_workspace_id
  databricks_group_prefix           = "${local.prefix}-group"
  databricks_metastore_grants       = local.databricks_metastore_grants
  databricks_catalog_grants         = local.databricks_catalog_grants
  databricks_catalog_name           = "${local.prefix}-catalog"
  gcp_region                        = data.google_client_config.this.region

  providers = {
    google.auth_session  = google.auth_session
    databricks.accounts  = databricks.accounts
    databricks.workspace = databricks.workspace
  }
}


## ---------------------------------------------------------------------------------------------------------------------
## HTTP DATA SOURCE
## 
## Download contents of gcs-connector-hadoop3-2.2.17-shaded  jar Databricks Unity Catalog LIBRARIES Volume.
## 
## Parameters:
## - `url`: Sample data URL.
## - `request_headers`: Mapping of HTTP request headers.
## ---------------------------------------------------------------------------------------------------------------------
data "http" "gcs_connector_hadoop" {
  url = "https://github.com/GoogleCloudDataproc/hadoop-connectors/releases/download/v2.2.17/gcs-connector-hadoop3-2.2.17-shaded.jar"

  # Optional request headers
  request_headers = {
    Accept          = "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7"
    Accept-Encoding = "gzip, deflate, br, zstd"
  }
}


## ---------------------------------------------------------------------------------------------------------------------
## DATABRICKS WORKSPACE CONFIG MODULE
## 
## This module configures a Databricks Workspace with the resources necessary to start utilizing spark/azure compute,
## and a bootstrapped Unity Catalog. Databricks Assets Bundles will also be ready to deploy onto the workspace with 
## pytest scripts ready to test spark capabilities.
## 
## Parameters:
## - `DATABRICKS_CLUSTERS`: Number of clusters to deploy in Databricks Workspace.
## - `databricks_cluster_name`: Prefix for Databricks Clusters. 
## - `databricks_catalog_name`: Name of Databricks Unity Catalog.
## - `databricks_schema_name`: Name of sample database to create in Unity Catalog.
## - `databricks_catalog_external_location_url`: Cloud Storage URL.
## - `databricks_cluster_spark_env_variable`: Map of Spark environment variables to assign to Databricks cluster.
## - `databricks_cluster_spark_conf_variable`: Map of Spark configuration variables to assign to Databricks cluster.
## - `databricks_cluster_library_files`: List of Databricks Unity Catalog Library Files to upload for install.
## - `databricks_workspace_group`: Databricks Workspace group to create for cluster policy permission.
## ---------------------------------------------------------------------------------------------------------------------
module "databricks_workspace_config" {
  source = "github.com/sim-parables/terraform-databricks?ref=ebaab7866a6be350d2c48246af64ad0b5332cde2"
  depends_on = [
    module.databricks_workspace,
    module.databricks_metastore
  ]

  DATABRICKS_CLUSTERS                      = var.DATABRICKS_CLUSTERS
  databricks_cluster_name                  = "${local.prefix}-cluster"
  databricks_catalog_name                  = module.databricks_metastore.databricks_catalog_name
  databricks_schema_name                   = local.schema_name
  databricks_catalog_external_location_url = module.databricks_metastore.databricks_external_location_url
  databricks_cluster_spark_env_variable    = local.spark_env_variables
  databricks_cluster_spark_conf_variable   = local.spark_conf_variables
  databricks_cluster_library_files         = local.databricks_cluster_library_files
  databricks_workspace_group               = "${local.prefix}-group"

  providers = {
    databricks.accounts  = databricks.accounts
    databricks.workspace = databricks.workspace
  }
}