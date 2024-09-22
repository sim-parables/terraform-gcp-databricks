<p float="left">
  <img id="b-0" src="https://img.shields.io/badge/terraform-%235835CC.svg?style=for-the-badge&logo=terraform&logoColor=white" height="25px"/>
  <img id="b-1" src="https://img.shields.io/badge/Google_Cloud-4285F4?style=for-the-badge&logo=google-cloud&logoColor=white" height="25px"/>
  <img id="b-2" src="https://img.shields.io/github/actions/workflow/status/sim-parables/terraform-gcp-blob-trigger/tf-integration-test.yml?style=flat&logo=github&label=CD%20(September%202024)" height="25px"/>
</p>

# Terraform GCP Databricks Workspace & Unity Catalog Module

A reusable module for creating & configuring Databricks Workspaces with Unity Catalog on Google Cloud Platform.

> [!IMPORTANT]
> These terraform modules and CI/CD Workflow Actions will have associated costs when deployed to the Google Cloud Platform and kept
> running for any given duration. Please use with caution!

## Usage


| :memo: NOTE                            |
|:---------------------------------------|
| Usage documentation under Construction |


## Inputs

| Name                             | Description                             | Type           | Required |
|:---------------------------------|:----------------------------------------|:---------------|:---------|
| DATABRICKS_ADMINISTRATOR         | DB Accounts & Workspace Admin email     | String         | Yes      |
| DATABRICKS_ACCOUNT_GOOGLE_MEMBER | GCP Member ID for DB Accounts Admin     | String         | Yes      |
| DATABRICKS_ACCOUNT_ID            | Databricks Account ID                   | String         | Yes      |
| DATABRICKS_CLI_PROFILE           | Databricks Config Profile Name for GCP  | String         | No       |
| DATABRICKS_CLUSTERS              | Number of Databricks Workspace Clusters | Integer        | No       |
| databricks_workspace_name        | DB Workspace Name                       | String         | No       |


## Outputs

| Name                                                  | Description                                    |
|:------------------------------------------------------|:-----------------------------------------------|
| databricks_workspace_host                             | Databricks (DB) Workspace URL                  |
| databricks_workspace_id                               | DB Workspace ID                                |
| databricks_access_token                               | DB Workspace Access Token                      |
| databricks_workspace_name                             | DB Workspace Name                              |
| databricks_secret_scope                               | DB Workspace Secret Scope Name                 |
| databricks_service_account_client_id_secret_name      | DB Workspace Secret Name for SA Client ID      |
| databricks_service_account_private_key_id_secret_name | DB Workspace Secret Name for SA Private Key ID |
| databricks_service_account_private_key_secret_name    | DB Workspace Secret Name for SA Private Key    |
| databricks_external_location_url                      | DB Unity Catalog External Location GCS URL     |
| databricks_cluster_ids                                | List of DB Workspace Cluster IDs               |
| google_secret_client_id_name                          | Google Secret Name for SP Client ID            |
| google_secret_client_secret_name                      | Google Secret Name for SP Client Secret        |

