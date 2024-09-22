terraform{
  required_providers {
    google = {
      source  = "hashicorp/google"
      configuration_aliases = [ google.auth_session ]
    }

    databricks = {
      source = "databricks/databricks"
      configuration_aliases = [ databricks.accounts ]
    }
  }
}


## ---------------------------------------------------------------------------------------------------------------------
## GOOGLE COMPUTE NETWORK RESOURCE
##
## This resource defines a Google Compute Engine network.
##
## Parameters:
## - `project`: The ID of the project that will contain the network.
## - `name`: The name of the network.
## - `auto_create_subnetworks`: Whether to enable the automatic creation of subnetworks.
## ---------------------------------------------------------------------------------------------------------------------
resource "google_compute_network" "this" {
  provider                = google.auth_session
  project                 = var.gcp_project_id
  name                    = var.gcp_network_name
  auto_create_subnetworks = false
}


## ---------------------------------------------------------------------------------------------------------------------
## GOOGLE COMPUTE SUBNETWORK RESOURCE
##
## This resource defines a subnetwork within a Google Compute Engine network.
##
## Parameters:
## - `name`: The name of the subnetwork.
## - `ip_cidr_range`: The range of internal addresses that are owned by this subnetwork.
## - `region`: The region where the subnetwork resides.
## - `network`: The self-link of the parent network.
## - `secondary_ip_range`: Optional. Specifies secondary IP ranges.
##   - `range_name`: The name of the secondary IP range.
##   - `ip_cidr_range`: The range of internal IP addresses that are owned by this secondary IP range.
## - `private_ip_google_access`: Whether VMs in this subnet can access Google services using an internal IP address.
## ---------------------------------------------------------------------------------------------------------------------
resource "google_compute_subnetwork" "this" {
  provider   = google.auth_session
  depends_on = [ google_compute_network.this ]

  name                      = "${var.gcp_network_name}-subnet"
  ip_cidr_range             = var.cidr_block
  region                    = var.gcp_region
  network                   = google_compute_network.this.id
  private_ip_google_access  = true

  secondary_ip_range {
    range_name    = "${var.gcp_network_name}-pods"
    ip_cidr_range = var.cidr_block_secondary_pods
  }

  secondary_ip_range {
    range_name    = "${var.gcp_network_name}-svc"
    ip_cidr_range = var.cidr_block_secondary_services
  }

  provisioner "local-exec" {
    when    = destroy
    command = "sleep 120"
  }
}


## ---------------------------------------------------------------------------------------------------------------------
## GOOGLE COMPUTE ROUTER RESOURCE
##
## This resource defines a Google Compute Engine router.
##
## Parameters:
## - `name`: The name of the router.
## - `region`: The region where the router resides.
## - `network`: The self-link of the parent network.
## ---------------------------------------------------------------------------------------------------------------------
resource "google_compute_router" "this" {
  provider   = google.auth_session
  depends_on = [ 
    google_compute_network.this,
    google_compute_subnetwork.this 
  ]

  name     = "${var.gcp_network_name}-router"
  region   = google_compute_subnetwork.this.region
  network  = google_compute_network.this.id
}


## ---------------------------------------------------------------------------------------------------------------------
## GOOGLE COMPUTE ROUTER NAT RESOURCE
##
## This resource defines a Google Compute Engine NAT (Network Address Translation) router.
##
## Parameters:
## - `name`: The name of the NAT router.
## - `router`: The name of the router to associate the NAT configuration with.
## - `region`: The region where the NAT router resides.
## - `nat_ip_allocate_option`: Specifies how external IP addresses should be allocated for NAT.
## - `source_subnetwork_ip_ranges_to_nat`: Specifies which subnetwork IP ranges should be NATed.
## ---------------------------------------------------------------------------------------------------------------------
resource "google_compute_router_nat" "this" {
  provider   = google.auth_session
  depends_on = [ google_compute_router.this ]

  name                               = "${var.gcp_network_name}-nat"
  router                             = google_compute_router.this.name
  region                             = google_compute_router.this.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
}


## ---------------------------------------------------------------------------------------------------------------------
## DATABRICKS MWS NETWORKS
##
## This resource defines a network configuration for Databricks MultiWorkspace Services (MWS).
## Note:
##   The Databricks Account CLI Profile associated GCP service account is the one which will
##   request the Databricks MWS Network creation and needs to be the service account
##   provisioned with IAM privileges to create. The Terraformed service account
##   WILL NOT be creating the Databricks MWS Network.
##
## Parameters:
## - `account_id`: The ID of the Databricks account.
## - `network_name`: The name of the network configuration.
## - `gcp_network_info`: Information about the Google Cloud Platform (GCP) network.
##   - `network_project_id`: The project ID of the GCP network.
##   - `vpc_id`: The ID of the VPC (Virtual Private Cloud).
##   - `subnet_id`: The ID of the subnet within the VPC.
##   - `subnet_region`: The region where the subnet resides.
##   - `pod_ip_range_name`: The name of the IP range for pods.
##   - `service_ip_range_name`: The name of the IP range for services.
## ---------------------------------------------------------------------------------------------------------------------
resource "databricks_mws_networks" "this" {
  provider   = databricks.accounts
  depends_on = [ google_compute_router_nat.this ]
  
  account_id   = var.DATABRICKS_ACCOUNT_ID
  network_name = substr(google_compute_network.this.name, 0, 30)
  gcp_network_info {
    network_project_id    = var.gcp_project_id
    vpc_id                = google_compute_network.this.name
    subnet_id             = google_compute_subnetwork.this.name
    subnet_region         = google_compute_subnetwork.this.region
    pod_ip_range_name     = "${var.gcp_network_name}-pods"
    service_ip_range_name = "${var.gcp_network_name}-svc"
  }
}

