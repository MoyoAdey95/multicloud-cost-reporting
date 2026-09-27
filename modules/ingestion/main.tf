# Where the nightly workflow puts the AWS and Azure files, and where BigQuery
# loads them to. Terraform owns the bucket, the dataset and the permissions.
# The raw tables themselves are created by the first load and replaced one
# month at a time after that, so the data is owned by the pipeline.

# BigQuery only loads from a bucket in the same location as the dataset, so
# the bucket is in the EU multi-region as well.
resource "google_storage_bucket" "landing" {
  project                     = var.project_id
  name                        = var.landing_bucket_name
  location                    = var.location
  storage_class               = "STANDARD"
  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"

  # The files are copies of exports that still exist at the source, so there
  # is nothing to keep once they have been loaded.
  lifecycle_rule {
    condition {
      age = var.landing_retention_days
    }
    action {
      type = "Delete"
    }
  }
}

resource "google_bigquery_dataset" "raw" {
  project     = var.project_id
  dataset_id  = var.raw_dataset_id
  location    = var.location
  description = "AWS and Azure cost exports as loaded, before any mapping."

  # The raw tables can be rebuilt from the exports, so a destroy is allowed
  # to take them with it.
  delete_contents_on_destroy = true
}

# Write to the landing bucket and nothing else in the project's storage.
resource "google_storage_bucket_iam_member" "ingest_landing" {
  bucket = google_storage_bucket.landing.name
  role   = "roles/storage.objectAdmin"
  member = var.ingest_member
}

# Create and replace tables in the raw dataset only.
resource "google_bigquery_dataset_iam_member" "ingest_raw" {
  project    = var.project_id
  dataset_id = google_bigquery_dataset.raw.dataset_id
  role       = "roles/bigquery.dataEditor"
  member     = var.ingest_member
}

# A load is a BigQuery job, and running jobs is granted at project level.
# This role runs jobs but gives no access to any data by itself.
resource "google_project_iam_member" "ingest_job_user" {
  project = var.project_id
  role    = "roles/bigquery.jobUser"
  member  = var.ingest_member
}
