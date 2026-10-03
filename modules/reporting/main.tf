# Views that put each provider's cost data on the same FOCUS columns, so the
# union and allocation views can treat the three as one. The SQL lives in
# sql/ next to this file so it can be read and reviewed as SQL.

resource "google_bigquery_dataset" "reporting" {
  project     = var.project_id
  dataset_id  = var.dataset_id
  location    = var.location
  description = "AWS, GCP and Azure cost data on shared FOCUS columns."

  # Views only. Nothing here holds data that cannot be rebuilt.
  delete_contents_on_destroy = true
}

locals {
  views = {
    focus_aws = templatefile("${path.module}/sql/focus_aws.sql", {
      raw_dataset = "${var.project_id}.${var.raw_dataset_id}"
    })
    focus_gcp = templatefile("${path.module}/sql/focus_gcp.sql", {
      gcp_focus_table = var.gcp_focus_table
    })
    focus_azure = templatefile("${path.module}/sql/focus_azure.sql", {
      raw_dataset = "${var.project_id}.${var.raw_dataset_id}"
    })
  }
}

resource "google_bigquery_table" "focus" {
  for_each = local.views

  project    = var.project_id
  dataset_id = google_bigquery_dataset.reporting.dataset_id
  table_id   = each.key

  # A view holds no data, so there is nothing for deletion protection to save.
  deletion_protection = false

  view {
    query          = each.value
    use_legacy_sql = false
  }
}
