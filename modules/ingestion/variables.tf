variable "project_id" {
  description = "Project the bucket and dataset are created in."
  type        = string
}

variable "location" {
  description = "Location for the bucket and dataset. Must match the billing export dataset."
  type        = string
}

variable "landing_bucket_name" {
  description = "Name of the bucket the workflow copies export files into."
  type        = string
}

variable "landing_retention_days" {
  description = "Days a landed file is kept before the lifecycle rule deletes it."
  type        = number
  default     = 30
}

variable "raw_dataset_id" {
  description = "Dataset the export files are loaded into."
  type        = string
}

variable "ingest_member" {
  description = "IAM member string of the identity that runs the ingestion."
  type        = string
}
