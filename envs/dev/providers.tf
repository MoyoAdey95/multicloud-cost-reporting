provider "google" {
  project = var.gcp_project
  region  = var.gcp_region

  default_labels = {
    project      = var.project
    env          = var.env
    owner        = var.owner
    "managed-by" = "terraform"
  }
}

# The AWS side only reads the cost export bucket, which is in eu-west-2.
provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile

  default_tags {
    tags = {
      project      = var.project
      env          = var.env
      owner        = var.owner
      "managed-by" = "terraform"
    }
  }
}

provider "azurerm" {
  subscription_id = var.azure_subscription_id

  # Storage calls go through Entra ID, the same as in azure-terraform-lab.
  storage_use_azuread = true

  features {}
}
