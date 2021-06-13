variable "project_id" {
  type        = string
  description = "The ID of the project where this VPC will be created"
}

variable "project_id" {
  type        = map(string)
  description = "Map of labels to put in resources"
  default     = {}
}

variable "service_account_id" {
  type        = string
  description = "Service account ID to manage tfstate and provide Terraform access to orchestrate resources"
}

variable "service_account_roles" {
  type        = list(string)
  description = "Service account roles (gcloud iam roles list)"
}

variable "backend_name" {
  type        = string
  description = "Terraform backend GCS bucket name"
}

variable "backend_location" {
  type        = string
  description = "Terraform backend GCS bucket (use one documented here https://cloud.google.com/storage/docs/locations)"
  default     = "US"
}

variable "kms_location" {
  type        = string
  description = "Terraform keyring location (use one documented here https://cloud.google.com/kms/docs/locations)"
  default     = "us"
}

variable "key_rotation_days" {
  type        = number
  description = "Number of days to set automatic encryption key rotation for bucket"
  default     = 15
}

variable "service_account_key_rotation_days" {
  type        = number
  description = "Number of days to set automatic key rotation for service account"
  default     = 30
}

variable "tfstate_path" {
  type        = string
  description = "Remote path on GCS bucket to put terraform tfstate with remote backend"
}

variable "backend_local_path" {
  type        = string
  description = "Local path to create terraform backend configuration file"
}
