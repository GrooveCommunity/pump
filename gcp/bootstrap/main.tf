locals {
  apis_to_enable = toset([
    "storage-component.googleapis.com",
    "storage-api.googleapis.com",
    "cloudkms.googleapis.com",
  ])
}

data "google_project" "project" {
  project_id = var.project_id
}

resource "google_project_service" "service" {
  for_each = local.apis_to_enable
  project  = var.project_id
  service  = each.value

  timeouts {
    create = "30m"
    update = "40m"
  }

  disable_dependent_services = false
  disable_on_destroy         = false
}

resource "google_kms_key_ring" "keyring" {
  project  = var.project_id
  name     = var.backend_name
  location = var.kms_location
}

resource "google_kms_crypto_key" "bucket_crypto_key" {
  name            = "${var.backend_name}-gcs-key"
  key_ring        = google_kms_key_ring.keyring.id
  rotation_period = "${var.key_rotation_days * 86400}s"
  purpose         = "ENCRYPT_DECRYPT"

  version_template {
    algorithm        = "GOOGLE_SYMMETRIC_ENCRYPTION"
    protection_level = "SOFTWARE"
  }

  lifecycle {
    prevent_destroy = true
  }

  labels = var.labels
}

resource "google_kms_crypto_key_iam_member" "bucket_crypto_key" {
  crypto_key_id = google_kms_crypto_key.bucket_crypto_key.id
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member        = "serviceAccount:service-${data.google_project.project.number}@gs-project-accounts.iam.gserviceaccount.com"
}

resource "google_storage_bucket" "terraform_backend" {
  project  = var.project_id
  name     = var.backend_name
  location = var.backend_location

  force_destroy               = false
  uniform_bucket_level_access = true

  versioning {
    enabled = true
  }

  encryption {
    default_kms_key_name = google_kms_crypto_key.bucket_crypto_key.id
  }

  storage_class = "STANDARD"

  labels = var.labels

  depends_on = [
    google_project_service.service,
    google_kms_crypto_key_iam_member.bucket_crypto_key,
  ]
}

resource "google_storage_bucket_iam_member" "member" {
  bucket = google_storage_bucket.terraform_backend.name
  role   = "roles/storage.admin"
  member = "serviceAccount:${google_service_account.terraform.email}"
}

resource "google_service_account" "terraform" {
  project      = var.project_id
  account_id   = var.service_account_id
  display_name = "Terraform (${var.service_account_id})"
}

resource "time_rotating" "service_account_rotation" {
  rotation_days = var.service_account_key_rotation_days
}

resource "google_service_account_key" "service_account_key" {
  service_account_id = google_service_account.terraform.name
  key_algorithm      = "KEY_ALG_RSA_2048"
  public_key_type    = "TYPE_X509_PEM_FILE"
  private_key_type   = "TYPE_GOOGLE_CREDENTIALS_FILE"
}

resource "google_project_iam_member" "service_account_role" {
  for_each = toset(var.service_account_roles)
  project  = var.project_id
  role     = each.value
  member   = "serviceAccount:${google_service_account.terraform.email}"
}


resource "google_project_iam_audit_config" "project" {
  project = var.project_id
  service = "allServices"
  audit_log_config {
    log_type = "ADMIN_READ"
  }
  audit_log_config {
    log_type = "DATA_READ"
  }
  audit_log_config {
    log_type = "DATA_WRITE"
  }
}

resource "google_storage_bucket_object" "service_account_key" {
  name    = "terraform/keys/${var.service_account_id}"
  content = base64decode(google_service_account_key.service_account_key.private_key)
  bucket  = google_storage_bucket.terraform_backend.name
}

resource "local_file" "backend" {
  content  = templatefile("${path.module}/templates/backend.tpl", { bucket_name : google_storage_bucket.terraform_backend.name, tfstate_path : var.tfstate_path })
  filename = "${var.backend_local_path}/backend.tf"
}
