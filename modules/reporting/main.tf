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

# The union reads the three provider views, and allocation reads the union, so
# each has to wait for the one before it to exist.
resource "google_bigquery_table" "focus_all" {
  project             = var.project_id
  dataset_id          = google_bigquery_dataset.reporting.dataset_id
  table_id            = "focus_all"
  deletion_protection = false

  view {
    query = templatefile("${path.module}/sql/focus_all.sql", {
      dataset = "${var.project_id}.${google_bigquery_dataset.reporting.dataset_id}"
    })
    use_legacy_sql = false
  }

  depends_on = [google_bigquery_table.focus]
}

resource "google_bigquery_table" "cost_allocation" {
  project             = var.project_id
  dataset_id          = google_bigquery_dataset.reporting.dataset_id
  table_id            = "cost_allocation"
  deletion_protection = false

  view {
    query = templatefile("${path.module}/sql/cost_allocation.sql", {
      dataset = "${var.project_id}.${google_bigquery_dataset.reporting.dataset_id}"
    })
    use_legacy_sql = false
  }

  depends_on = [google_bigquery_table.focus_all]
}

resource "google_bigquery_table" "reconciliation" {
  project             = var.project_id
  dataset_id          = google_bigquery_dataset.reporting.dataset_id
  table_id            = "reconciliation"
  deletion_protection = false

  view {
    query = templatefile("${path.module}/sql/reconciliation.sql", {
      dataset            = "${var.project_id}.${google_bigquery_dataset.reporting.dataset_id}"
      raw_dataset        = "${var.project_id}.${var.raw_dataset_id}"
      gcp_detailed_table = var.gcp_detailed_table
    })
    use_legacy_sql = false
  }

  depends_on = [google_bigquery_table.focus_all]
}
