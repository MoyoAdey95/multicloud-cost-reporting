variable "project_id" {
  description = "Project the reporting dataset is created in."
  type        = string
}

variable "location" {
  description = "Location of the reporting dataset. Must match the raw and billing export datasets."
  type        = string
}

variable "dataset_id" {
  description = "ID of the reporting dataset."
  type        = string
}

variable "raw_dataset_id" {
  description = "Dataset holding the raw AWS and Azure tables."
  type        = string
}

variable "gcp_focus_table" {
  description = "Fully qualified GCP FOCUS export table, project.dataset.table."
  type        = string
}
