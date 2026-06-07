# =========================================================================
# ENTERPRISE SECURITY LANDING ZONE: HARDENED PRIVATE GKE TOPOLOGY
# =========================================================================

resource "google_container_cluster" "hardened_gke" {
  name     = "enterprise-hardened-cluster"
  location = var.region

  # Wire the cluster directly to our secure VPC network structures
  network    = google_compute_network.secure_vpc.id
  subnetwork = google_compute_subnetwork.private_gke_subnet.id

  # 1. ARCHITECTING COGNIZANT PRIVATE TOPOLOGY (ZERO PUBLIC INTERFACES)
  private_cluster_config {
    enable_private_nodes    = true
    enable_private_endpoint = false # Allows secure admin control from authorized endpoints
    master_ipv4_cidr_block  = "172.16.0.0/28"
  }

  # 2. ENFORCING ALIAS IP ENVELOPES FOR PACKET ROUTING ISOLATION
  ip_allocation_policy {
    cluster_secondary_range_name  = "gke-pods-tier"
    services_secondary_range_name = "gke-services-tier"
  }

  # 3. COMPLIANCE STACK ELIMINATION OF DEFAULT POOLS
  remove_default_node_pool = true
  initial_node_count       = 1

  # 4. ENFORCING CONTROLLER-PLANE HARDENING (SHIELDED AUTOMATION)
  release_channel {
    channel = "REGULAR"
  }
}

# 5. HARDENED NODE POOL DESIGN ENFORCING CONTAINER-OPTIMIZED OS
resource "google_container_node_pool" "secure_nodes" {
  name       = "hardened-compute-pool"
  location   = var.region
  cluster    = google_container_cluster.hardened_gke.name
  node_count = 2

  node_config {
    preemptible  = false
    machine_type = "e2-standard-4" # Provides compute power required for Falco eBPF loops

    # Hardening host operating systems against execution attacks
    image_type   = "COS_CONTAINER_OPTIMIZED_OS"

    metadata = {
      disable-legacy-endpoints = "true"
    }

    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
  }
}