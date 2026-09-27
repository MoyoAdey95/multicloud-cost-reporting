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
