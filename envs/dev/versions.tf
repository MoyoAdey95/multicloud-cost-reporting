terraform {
  required_version = ">= 1.11"

  # One root module talks to all three clouds, because the pipeline reads
  # from AWS and Azure and writes into GCP.
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 8.4"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.66"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 5.7"
    }
  }

  # State lives in its own project, next to everything else this repo
  # creates. The gcs backend locks natively, so there is no lock table.
  backend "gcs" {
    bucket = "moyo-cost-reporting-tfstate"
    prefix = "multicloud-cost-reporting/dev"
  }
}
