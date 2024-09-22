terraform {
  required_providers {
    databricks = {
      source = "databricks/databricks"
      configuration_aliases = [ databricks.accounts, ]
    }
    google = {
      source  = "hashicorp/google"
      configuration_aliases = [ google.auth_session, ]
    }
  }
}


## ---------------------------------------------------------------------------------------------------------------------
## DATABRICKS VPC MODULE
##
## This module configures the VPC for Databricks.
##
## Parameters:
## - `databricks_account_id`: The Databricks account ID.
## - `gcp_project_id`: The Google Cloud project ID.
## - `gcp_region`: The Google Cloud region.
## ---------------------------------------------------------------------------------------------------------------------
module "databricks_vpc" {
  source     = "./modules/gcp_databricks_vpc"

  DATABRICKS_ACCOUNT_ID = var.DATABRICKS_ACCOUNT_ID
  gcp_network_name      = "${var.databricks_workspace_name}-vpc"
  gcp_project_id        = var.gcp_project_id
  gcp_region             = var.gcp_region

  providers = {
    google.auth_session = google.auth_session
    databricks.accounts = databricks.accounts
  }
}

## ---------------------------------------------------------------------------------------------------------------------
## DATABRICKS MWS WORKSPACES RESOURCE
##
## This resource creates a Databricks MWS workspace.
##
## Parameters:
## - `account_id`: The Databricks account ID.
## - `workspace_name`: The name of the workspace.
## - `location`: The location of the workspace.
## - `cloud_resource_container`: Configuration for the cloud resource container.
## - `network_id`: The network ID.
## - `gke_config`: Configuration for the GKE (Google Kubernetes Engine).
## ---------------------------------------------------------------------------------------------------------------------
resource "databricks_mws_workspaces" "this" {
  provider       = databricks.accounts
  depends_on     = [ module.databricks_vpc ]
  
  account_id     = var.DATABRICKS_ACCOUNT_ID
  workspace_name = substr(var.databricks_workspace_name, 0, 30)
  location       = module.databricks_vpc.subnet_region
  cloud_resource_container {
    gcp {
      project_id = var.gcp_project_id
    }
  }

  network_id = module.databricks_vpc.network_id
  gke_config {
    connectivity_type = var.gcp_databricks_connectivity_type
    master_ip_range   = var.gcp_databricks_ip_range
  }

  token{}
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
  depends_on = [ databricks_mws_workspaces.this ]
  
  role_id     = replace(var.gcp_databricks_service_account_role, "-", "_")
  title       = "Databricks Workspace Service Role"
  permissions = [
    # Customer Workplace Service Account Roles
    "compute.globalOperations.get",
    "compute.instanceGroups.get",
    "compute.instanceGroups.list",
    "compute.instances.get",
    "compute.instances.list",
    "compute.instances.setLabels",
    "compute.disks.get",
    "compute.disks.setLabels",
    "compute.networks.access",
    "compute.networks.create",
    "compute.networks.delete",
    "compute.networks.getEffectiveFirewalls",
    "compute.networks.update",
    "compute.networks.updatePolicy",
    "compute.networks.use",
    "compute.networks.useExternalIp",
    "compute.regionOperations.get",
    "compute.routers.create",
    "compute.routers.delete",
    "compute.routers.get",
    "compute.routers.update",
    "compute.routers.use",
    "compute.subnetworks.create",
    "compute.subnetworks.delete",
    "compute.subnetworks.expandIpCidrRange",
    "compute.subnetworks.getIamPolicy",
    "compute.subnetworks.setIamPolicy",
    "compute.subnetworks.setPrivateIpGoogleAccess",
    "compute.subnetworks.update",
    "compute.subnetworks.use",
    "compute.subnetworks.useExternalIp",
    "container.clusterRoleBindings.create",
    "container.clusterRoleBindings.get",
    "container.clusterRoles.bind",
    "container.clusterRoles.create",
    "container.clusterRoles.get",
    "container.clusters.create",
    "container.clusters.delete",
    "container.clusters.get",
    "container.clusters.getCredentials",
    "container.clusters.list",
    "container.clusters.update",
    "container.configMaps.create",
    "container.configMaps.get",
    "container.configMaps.update",
    "container.customResourceDefinitions.create",
    "container.customResourceDefinitions.get",
    "container.customResourceDefinitions.update",
    "container.daemonSets.create",
    "container.daemonSets.get",
    "container.daemonSets.update",
    "container.deployments.create",
    "container.deployments.get",
    "container.deployments.update",
    "container.jobs.create",
    "container.jobs.get",
    "container.jobs.update",
    "container.namespaces.create",
    "container.namespaces.get",
    "container.namespaces.list",
    "container.operations.get",
    "container.pods.get",
    "container.pods.getLogs",
    "container.pods.list",
    "container.roleBindings.create",
    "container.roleBindings.get",
    "container.roles.bind",
    "container.roles.create",
    "container.roles.get",
    "container.secrets.create",
    "container.secrets.get",
    "container.secrets.update",
    "container.serviceAccounts.create",
    "container.serviceAccounts.get",
    "container.services.create",
    "container.services.get",
    "container.thirdPartyObjects.create",
    "container.thirdPartyObjects.delete",
    "container.thirdPartyObjects.get",
    "container.thirdPartyObjects.list",
    "container.thirdPartyObjects.update",
    "storage.buckets.create",
    "storage.buckets.delete",
    "storage.buckets.get",
    "storage.buckets.getIamPolicy",
    "storage.buckets.list",
    "storage.buckets.setIamPolicy",
    "storage.buckets.update",
    "storage.objects.create",
    "storage.objects.delete",
    "storage.objects.get",
    "storage.objects.list",
    "storage.objects.update"
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

  project = var.gcp_project_id
  role    = google_project_iam_custom_role.this.id
  members = [
    "serviceAccount:${databricks_mws_workspaces.this.gcp_workspace_sa}"
  ]
}