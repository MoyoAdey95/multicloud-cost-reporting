# Composition root for the dev environment. Modules do the work and this file
# wires them together.

# A new project starts without the identity APIs. Turning them on here keeps
# them in the record. disable_on_destroy is off so a destroy never switches
# off an API something else in the project still uses.
resource "google_project_service" "this" {
  for_each = toset([
    "cloudresourcemanager.googleapis.com",
    "iam.googleapis.com",
    "iamcredentials.googleapis.com",
    "sts.googleapis.com",
  ])

  project            = var.gcp_project
  service            = each.value
  disable_on_destroy = false
}

module "github_oidc_gcp" {
  source = "../../modules/github-oidc-gcp"

  project_id                   = var.gcp_project
  pool_id                      = "github"
  pool_display_name            = "GitHub"
  provider_id                  = "github-actions"
  github_owner_id              = var.github_owner_id
  github_repository_id         = var.github_repository_id
  github_subject               = local.github_subject
  service_account_id           = "github-cost-ingest"
  service_account_display_name = "GitHub cost ingestion"

  depends_on = [google_project_service.this]
}

# Read access to the FOCUS export and nothing else. ListBucket is limited to
# the export prefix, so the role cannot even see what else is in the bucket.
data "aws_iam_policy_document" "cost_export_read" {
  statement {
    sid       = "ListExportPrefix"
    actions   = ["s3:ListBucket"]
    resources = ["arn:aws:s3:::${var.aws_export_bucket}"]

    condition {
      test     = "StringLike"
      variable = "s3:prefix"
      values   = ["${var.aws_export_prefix}/*"]
    }
  }

  statement {
    sid       = "ReadExportObjects"
    actions   = ["s3:GetObject"]
    resources = ["arn:aws:s3:::${var.aws_export_bucket}/${var.aws_export_prefix}/*"]
  }
}

module "github_oidc_aws" {
  source = "../../modules/github-oidc-aws"

  role_name        = "github-cost-ingest"
  role_description = "Assumed by GitHub Actions on main to read the AWS cost export."
  github_subject   = local.github_subject
  policy_json      = data.aws_iam_policy_document.cost_export_read.json
}

# The Azure side of this repo gets its own resource group, so tearing down
# another lab never reaches it. The cost export itself stays in
# rg-cost-exports, which was built by hand before this repo existed.
resource "azurerm_resource_group" "this" {
  name     = "rg-cost-reporting"
  location = var.azure_location
  tags     = local.common_tags
}

# Built from its parts rather than read with a data source. The storage
# account data source also fetches the account keys, and those would then
# sit in the state file.
locals {
  azure_export_container_id = join("/", [
    "/subscriptions/${var.azure_subscription_id}",
    "resourceGroups/${var.azure_export_resource_group}",
    "providers/Microsoft.Storage/storageAccounts/${var.azure_export_storage_account}",
    "blobServices/default/containers/${var.azure_export_container}",
  ])
}

module "github_oidc_azure" {
  source = "../../modules/github-oidc-azure"

  identity_name       = "id-github-cost-ingest"
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  credential_name     = "github-main"
  github_subject      = local.github_subject
  tags                = local.common_tags

  # Read on the one container, not the storage account or the subscription.
  role_assignments = {
    export-read = {
      scope = local.azure_export_container_id
      role  = "Storage Blob Data Reader"
    }
  }
}

data "azurerm_client_config" "current" {}

module "ingestion" {
  source = "../../modules/ingestion"

  project_id          = var.gcp_project
  location            = var.bq_location
  landing_bucket_name = "moyo-cost-reporting-landing"
  raw_dataset_id      = "cost_raw"
  ingest_member       = module.github_oidc_gcp.service_account_member
}

module "reporting" {
  source = "../../modules/reporting"

  project_id      = var.gcp_project
  location        = var.bq_location
  dataset_id      = "cost_reporting"
  raw_dataset_id  = module.ingestion.raw_dataset_id
  gcp_focus_table = var.gcp_focus_table

  gcp_detailed_table = var.gcp_detailed_table
}
