variable "gcp_project" {
  description = "GCP project that holds the state bucket, datasets and identity pool."
  type        = string
  default     = "multicloud-cost-reporting-lab"
}

# Only read from. The GCP billing export stays where it was switched on,
# because moving an export starts it again with no history.
variable "billing_export_project" {
  description = "GCP project that holds the Cloud Billing export datasets."
  type        = string
  default     = "moyo-cloud-lab"
}

variable "gcp_region" {
  description = "Default GCP region for regional resources."
  type        = string
  default     = "europe-west2"
}

# BigQuery only joins datasets in the same location, and the billing export
# is in the EU multi-region, so every dataset here has to be EU as well.
variable "bq_location" {
  description = "Location for BigQuery datasets."
  type        = string
  default     = "EU"
}

variable "aws_region" {
  description = "AWS region of the cost export bucket."
  type        = string
  default     = "eu-west-2"
}

variable "aws_profile" {
  description = "Local AWS CLI profile used when running Terraform by hand."
  type        = string
  default     = "personal"
}

# A subscription ID identifies the subscription but grants nothing on its own.
variable "azure_subscription_id" {
  description = "Azure subscription that holds the cost export storage account."
  type        = string
  default     = "fb41774d-87cb-41eb-997c-9dbe498cf34e"
}

variable "azure_location" {
  description = "Azure region for the few resources created on the Azure side."
  type        = string
  default     = "uksouth"
}

variable "project" {
  description = "Project tag or label applied to every resource."
  type        = string
  default     = "multicloud-cost-reporting"
}

variable "env" {
  description = "Environment tag or label applied to every resource."
  type        = string
  default     = "dev"
}

variable "owner" {
  description = "Owner tag or label applied to every resource."
  type        = string
  default     = "moyo"
}
