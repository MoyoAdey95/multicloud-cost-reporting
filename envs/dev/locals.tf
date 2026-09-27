# google and aws apply these from the provider block. azurerm has no default
# tags, so Azure resources pass this map in explicitly.
locals {
  common_tags = {
    project      = var.project
    env          = var.env
    owner        = var.owner
    "managed-by" = "terraform"
  }
}
