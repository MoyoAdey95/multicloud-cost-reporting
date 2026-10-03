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

variable "github_owner_id" {
  description = "Numeric ID of the GitHub account that owns this repository."
  type        = string
  default     = "212127446"
}

variable "github_repository_id" {
  description = "Numeric ID of this repository on GitHub."
  type        = string
  default     = "1383789639"
}

# Read from GitHub with
# gh api repos/MoyoAdey95/multicloud-cost-reporting/actions/oidc/customization/sub
# rather than written by hand. The repo uses the immutable form, with the
# owner and repository IDs in it.
variable "github_sub_prefix" {
  description = "Start of the OIDC sub claim GitHub issues for this repository."
  type        = string
  default     = "repo:MoyoAdey95@212127446/multicloud-cost-reporting@1383789639"
}

# Read from the export definition with aws bcm-data-exports get-export.
variable "aws_export_bucket" {
  description = "S3 bucket the AWS Data Exports FOCUS export writes to."
  type        = string
  default     = "moyoadey-cost-exports"
}

variable "aws_export_prefix" {
  description = "Prefix under which the export writes its files."
  type        = string
  default     = "cost-exports"
}

# Read from the export definition with az costmanagement export show.
variable "azure_export_resource_group" {
  description = "Resource group of the storage account the Azure cost export writes to."
  type        = string
  default     = "rg-cost-exports"
}

variable "azure_export_storage_account" {
  description = "Storage account the Azure cost export writes to."
  type        = string
  default     = "moyoadeycostexports"
}

variable "azure_export_container" {
  description = "Blob container the Azure cost export writes to."
  type        = string
  default     = "cost-exports"
}

# Google creates this dataset and names it itself when the FOCUS export is
# switched on, which is why it is not in billing_export with the detailed one.
variable "gcp_focus_table" {
  description = "GCP Cloud Billing FOCUS export table, project.dataset.table."
  type        = string
  default     = "moyo-cloud-lab.gcp_billing_immutable_01614A_44C4CF_9E48D3_eu.gcp_billing_export_focus_01614A_44C4CF_9E48D3"
}

# The detailed export sits in billing_export, the dataset it was switched on in.
variable "gcp_detailed_table" {
  description = "GCP Cloud Billing detailed usage export table, project.dataset.table."
  type        = string
  default     = "moyo-cloud-lab.billing_export.gcp_billing_export_resource_v1_01614A_44C4CF_9E48D3"
}
