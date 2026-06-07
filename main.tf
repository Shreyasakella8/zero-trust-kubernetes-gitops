# =========================================================================
# ENTERPRISE SECURITY LANDING ZONE: ISOLATED INDUSTRIAL NETWORKING (GCP)
# =========================================================================

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

# 1. HARDENED VIRTUAL PRIVATE CLOUD (VPC)
resource "google_compute_network" "secure_vpc" {
  name                    = "enterprise-secure-vpc"
  auto_create_subnetworks = false
  routing_mode            = "REGIONAL"
}

# 2. ISOLATED COMPUTE SUBNET WITH PRIVATE GOOGLE ACCESS
resource "google_compute_subnetwork" "private_gke_subnet" {
  name                     = "private-gke-subnet"
  ip_cidr_range            = "10.0.0.0/20"
  network                  = google_compute_network.secure_vpc.id
  region                   = var.region
  private_ip_google_access = true

  # Secondary IP Ranges for Pods and Services (Required for GKE Alias IPs)
  secondary_ip_range {
    range_name    = "gke-pods-tier"
    ip_cidr_range = "10.4.0.0/14"
  }
  secondary_ip_range {
    range_name    = "gke-services-tier"
    ip_cidr_range = "10.8.0.0/20"
  }
}

# 3. ASYMMETRIC EGRESS CLOUD ROUTER (NO PUBLIC INGRESS SURFACES)
resource "google_compute_router" "egress_router" {
  name    = "secure-egress-router"
  region  = var.region
  network = google_compute_network.secure_vpc.id
}

# 4. CLOUD NAT ENGINE (Enables safe outbound updates while hiding internal node IPs)
resource "google_compute_router_nat" "secure_nat" {
  name                               = "secure-cloud-nat"
  router                             = google_compute_router.egress_router.name
  region                             = var.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "LIST_OF_SUBNETWORKS"

  subnetwork {
    name                    = google_compute_subnetwork.private_gke_subnet.id
    source_ip_ranges_to_nat = ["PRIMARY_IP_RANGE", "LIST_OF_SECONDARY_IP_RANGES"]
    secondary_ip_range_names = ["gke-pods-tier", "gke-services-tier"]
  }
}
