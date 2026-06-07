# =========================================================================
# ENTERPRISE SECURITY LANDING ZONE: PARAMETER CONFIGURATION VARIABLES
# =========================================================================

variable "project_id" {
  type        = string
  description = "The target Google Cloud Platform (GCP) Project ID for infrastructure deployment."
}

variable "region" {
  type        = string
  description = "The target GCP region where regional infrastructure resources will reside."
  default     = "europe-west2" # Defaulting to London, UK to align with enterprise location targeting
}

variable "environment" {
  type        = string
  description = "Deployment environment tag for GRC asset tracking and lifecycle isolation."
  default     = "production"
}