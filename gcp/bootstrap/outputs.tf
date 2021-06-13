output "keyring" {
  description = "KMS keyring used to store tfstate bucket encryption key"
  value       = google_kms_key_ring.keyring
}

output "tfstate_bucket" {
  description = "Bucket created to be Terraform's backend"
  value       = google_storage_bucket.terraform_backend
}

output "service_account" {
  description = "Service Account to be used by terraform"
  value       = google_service_account.terraform
}

output "service_account_key" {
  description = "Service Account key to be used as Google credential to orchestrate infrastructure"
  sensitive   = true
  value       = google_service_account_key.service_account_key
}

output "service_account_key_object" {
  description = "This module saves the newly created service account key in the bucket used to store the tfstate, so this output value is a reference to the object storing json-encoded key"
  value       = google_storage_bucket_object.service_account_key
}
