terraform {
  backend "gcs" {
    bucket  = "${bucket_name}"
    prefix  = "terraform/state/${tfstate_path}"
  }
}
