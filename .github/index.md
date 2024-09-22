# Github Action Workflows

[Github Actions](https://docs.github.com/en/actions) to automate, customize, and execute your software development workflows coupled with the repository.

## Local Actions

Validate Github Workflows locally with [Nekto's Act](https://nektosact.com/introduction.html). More info found in the Github Repo [https://github.com/nektos/act](https://github.com/nektos/act).

### Prerequisits

```
cat <<EOF > ~/creds/gcp.secrets
# Terraform.io Token
TF_API_TOKEN=[COPY/PASTE MANUALY]

# Github PAT
GITHUB_TOKEN=$(gh auth token)

# GCP
GOOGLE_PROJECT=$(gcloud config get-value project)
GOOGLE_PROJECT_ID=$(gcloud config get-value project)
GOOGLE_REGION=$(gcloud config get-value run/region)
GOOGLE_PROJECT_NUMBER=$(gcloud projects list \
--filter="$(gcloud config get-value project)" \
--format="value(PROJECT_NUMBER)")
GOOGLE_OAUTH_ACCESS_TOKEN=$(gcloud auth print-access-token)
GCP_IMPERSONATE_SERVICE_ACCOUNT_EMAIL=[COPY/PASTE MANUALY]
GCP_WORKLOAD_IDENTITY_PROVIDER=$(gcloud iam workload-identity-pools providers describe "${PROVIDER_NAME}" \
  --project="$(gcloud config get-value project)" \
  --location="global" \
  --workload-identity-pool="${WORKLOAD_IDENTITY_POOL_NAME}" \
  --format="value(name)")
EOF
```

### Refreshing local auth token
Local account impersonation authentication tokens only have a lifetime of 60 minutes.
Refresh often:

```
sed -i -E "s/(GOOGLE_OAUTH_ACCESS_TOKEN\=).*/\1$(gcloud auth print-access-token)/" ~/creds/gcp.secrets
```

### Manual Dispatch Testing

```
# Try the Terraform Read job first
act -j terraform-dispatch-plan \
    -e .github/local.json \
    --secret-file ~/creds/gcp.secrets \
    --var DATABRICKS_ADMINISTRATOR=$(git config user.email) \
    --remote-name $(git remote show)

act -j terraform-dispatch-apply \
    -e .github/local.json \
    --secret-file ~/creds/gcp.secrets \
    --var DATABRICKS_ADMINISTRATOR=$(git config user.email) \
    --remote-name $(git remote show)

act -j terraform-dispatch-test \
    -e .github/local.json \
    --secret-file ~/creds/gcp.secrets \
    --var DATABRICKS_ADMINISTRATOR=$(git config user.email) \
    --remote-name $(git remote show)

act -j terraform-dispatch-destroy \
    -e .github/local.json \
    --secret-file ~/creds/gpp.secrets \
    --var DATABRICKS_ADMINISTRATOR=$(git config user.email) \
    --remote-name $(git remote show)
```

### Integration Testing

```
# Create an artifact location to upload/download between steps locally
mkdir /tmp/artifacts

# Run the full Integration test with
act -j terraform-integration-destroy \
    -e .github/local.json \
    --secret-file ~/creds/gcp.secrets \
    --remote-name $(git remote show) \
    --artifact-server-path /tmp/artifacts
```

### Local Testing

```
# Configure Databricks CLI
databricks configure \
  --profile GCP_WORKSPACE \
  --host $(terraform -chdir=./test output -raw databricks_workspace_host) \
  --token <<EOF
  $(terraform -chdir=./test output -raw databricks_access_token)
EOF

export SERVICE_ACCOUNT_KEY_NAME=$(terraform -chdir=./test output -raw google_secret_client_id_name)
export SERVICE_ACCOUNT_KEY_SECRET=$(terraform -chdir=./test output -raw google_secret_client_secret_name)
export DATABRICKS_CLUSTER_ID=$(terraform -chdir=./test output -json databricks_cluster_ids | jq -r '.[0]')
export OUTPUT_DIR=$(terraform -chdir=./test output -raw databricks_external_location_url)
export OUTPUT_TABLE=$(terraform -chdir=./test output -json databricks_unity_catalog_table_paths | jq -r '.[0]')
export EXAMPLE_HOLDING_FILE_PATH=$(terraform -chdir=./test output -raw databricks_example_holdings_data_path)
export EXAMPLE_WEATHER_FILE_PATH=$(terraform -chdir=./test output -raw databricks_example_weather_data_path)

# Initialize Databricks Asset Bundle
# DO NOT user hyphens "-" in project name - will cause package namespace to be broken in Python
echo "{
  \"project_name\": \"sim_parabales_dab_example\",
  \"distribution_list\": \"$(git config user.email)\",
  \"databricks_cli_profile\": \"GCP_WORKSPACE\",
  \"databricks_cloud_provider\": \"GCP\",
  \"databricks_service_account_key_name\": \"$SERVICE_ACCOUNT_KEY_NAME\",
  \"databricks_service_account_key_secret\": \"$SERVICE_ACCOUNT_KEY_SECRET\"
}" > databricks_dab_template_config

databricks bundle init https://github.com/sim-parables/databricks-xcloud-asset-bundle-template \
  --output-dir=dab_solution \
  --profile=GCP_WORKSPACE \
  --config-file=databricks_dab_template_config

cd dab_solution
python3 run_local.py \
  --test_entrypoint="$(pwd)/tests/entrypoint.py" \
  --test_path="$(pwd)/tests/unit/local/test_examples.py" \
  --csv_path=https://duckdb.org/data/holdings.csv

python3 run_local.py \
  --test_entrypoint="$(pwd)/tests/entrypoint.py" \
  --test_path="$(pwd)/tests/integration/test_output.py" \
  --csv_path=https://duckdb.org/data/weather.csv

export $(cat .env)
python3 run_local.py \
  --test_entrypoint="$(pwd)/tests/entrypoint.py" \
  --test_path="$(pwd)/tests/integration/test_gcp.py"

python3 run_local.py \
  --test_entrypoint="$(pwd)/tests/entrypoint.py" \
  --test_path="$(pwd)/tests/unit/local/test_examples.py" \
  --csv_path=https://duckdb.org/data/holdings.csv

python3 run_local.py \
  --test_entrypoint="$(pwd)/tests/entrypoint.py" \
  --test_path="$(pwd)/tests/integration/test_output.py" \
  --output_path=$OUTPUT_DIR

databricks bundle deploy \
  --var="databricks_cluster_id=$DATABRICKS_CLUSTER_ID,csv_holdings_path=$EXAMPLE_HOLDING_FILE_PATH,csv_weather_path=$EXAMPLE_WEATHER_FILE_PATH,output_path=$OUTPUT_DIR,output_table=$OUTPUT_TABLE" \
  --profile=GCP_WORKSPACE

databricks bundle run sim_parabales_dab_example_example_unit_test \
  --var="databricks_cluster_id=$DATABRICKS_CLUSTER_ID,csv_holdings_path=$EXAMPLE_HOLDING_FILE_PATH,csv_weather_path=$EXAMPLE_WEATHER_FILE_PATH,output_path=$OUTPUT_DIR,output_table=$OUTPUT_TABLE" \
  --profile=GCP_WORKSPACE

databricks bundle run sim_parabales_dab_example_example_integration_test \
  --var="databricks_cluster_id=$DATABRICKS_CLUSTER_ID,csv_holdings_path=$EXAMPLE_HOLDING_FILE_PATH,csv_weather_path=$EXAMPLE_WEATHER_FILE_PATH,output_path=$OUTPUT_DIR,output_table=$OUTPUT_TABLE" \
  --profile=GCP_WORKSPACE

databricks bundle run sim_parabales_dab_example_example_output \
  --var="databricks_cluster_id=$DATABRICKS_CLUSTER_ID,csv_holdings_path=$EXAMPLE_HOLDING_FILE_PATH,csv_weather_path=$EXAMPLE_WEATHER_FILE_PATH,output_path=$OUTPUT_DIR,output_table=$OUTPUT_TABLE" \
  --profile=GCP_WORKSPACE

databricks bundle run sim_parabales_dab_example_example_output_uc \
  --var="databricks_cluster_id=$DATABRICKS_CLUSTER_ID,csv_holdings_path=$EXAMPLE_HOLDING_FILE_PATH,csv_weather_path=$EXAMPLE_WEATHER_FILE_PATH,output_path=$OUTPUT_DIR,output_table=$OUTPUT_TABLE" \
  --profile=GCP_WORKSPACE
```

### Unit Testing

```
act -j terraform-unit-tests \
  -e .github/local.json \
  --secret-file ~/creds/gcp.secrets \
  --remote-name $(git remote show)
```