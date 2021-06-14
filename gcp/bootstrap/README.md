# GCP Terraform Bootstrap

This module is an all-in-one bootstrap for Google Cloud Platform Terraform projects. It provides:

- A Google Cloud Storage bucket with symmetric encryption keys stored in KMS with the properly rotation settings
- IAM auditing configuration
- A Service Account to be used for by Terraform to create other resources like VPC, GKE clusters and etc (also with automatic private key rotation settings)
- And an extra sugar: it creates the `backend.tf` file where you need to put your main module

This module must be executed with an user account to provision the bootstrap resources.

## Usage Example

```hcl
module "bootstrap" {
  source = "git::ssh://git@github.com:GrooveCommunity/tf-modules.git//gcp/bootstrap?ref=main"
  
  # gcloud projects list
  # Get the "PROJECT_ID" column value
  project_id = "upper-blueprint"
  
  # https://cloud.google.com/storage/docs/locations
  backend_location = "US"
  backend_name     = "myawesomeapp-tfstate"

  service_account_id = "myawesomeapp-terraform"
  # Roles to bind to service account (gcloud iam roles list)
  service_account_roles = [
    "roles/compute.networkAdmin",
    "roles/compute.admin",
    "roles/container.clusterAdmin",
  ]
  
  # Must be in the available for the same location of the bucket
  # https://cloud.google.com/kms/docs/locations
  kms_location                      = "us"
  # Key used to encrypt tfstate bucket
  kms_key_rotation_days                 = 30
  # This rotation is done by terraform, so if you want to automate this, you should run the bootstrap regularly
  service_account_key_rotation_days = 30
  
  # The full path will be gs://${var.backend_name}/terraform/state/${var.tfstate_path}
  tfstate_path       = "myawesomeapp"
  # Where to generate the backend.tf file
  backend_local_path = abspath(path.root)

  labels = {
    "my-label" = "my-value"
  }
}
```

## Requirements

| Name        | Version   |
| ----------- | --------- |
| terraform   | >= 0.13.0 |
| google      | ~> 3.45   |
| google-beta | ~> 3.45   |

## Providers

| Name   | Version |
| ------ | ------- |
| google | ~> 3.45 |
| local  | n/a     |
| time   | n/a     |

## Modules

No Modules.

## Resources

| Name                                                                                                                                         |
| -------------------------------------------------------------------------------------------------------------------------------------------- |
| [google_kms_crypto_key](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/kms_crypto_key)                       |
| [google_kms_crypto_key_iam_member](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/kms_crypto_key_iam_member) |
| [google_kms_key_ring](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/kms_key_ring)                           |
| [google_project](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/project)                                  |
| [google_project_iam_audit_config](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/project_iam_audit_config)   |
| [google_project_iam_member](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/project_iam_member)               |
| [google_project_service](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/project_service)                     |
| [google_service_account](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/service_account)                     |
| [google_service_account_key](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/service_account_key)             |
| [google_storage_bucket](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/storage_bucket)                       |
| [google_storage_bucket_iam_member](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/storage_bucket_iam_member) |
| [google_storage_bucket_object](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/storage_bucket_object)         |
| [local_file](https://registry.terraform.io/providers/hashicorp/local/latest/docs/resources/file)                                             |
| [time_rotating](https://registry.terraform.io/providers/hashicorp/time/latest/docs/resources/rotating)                                       |

## Inputs

| Name                                  | Description                                                                                            | Type           | Default | Required |
| ------------------------------------- | ------------------------------------------------------------------------------------------------------ | -------------- | ------- | :------: |
| backend\_local\_path                  | Local path to create terraform backend configuration file                                              | `string`       | n/a     |   yes    |
| backend\_location                     | Terraform backend GCS bucket (use one documented here https://cloud.google.com/storage/docs/locations) | `string`       | `"US"`  |    no    |
| backend\_name                         | Terraform backend GCS bucket name                                                                      | `string`       | n/a     |   yes    |
| kms\_key\_rotation\_days                   | Number of days to set automatic encryption key rotation for bucket                                     | `number`       | `15`    |    no    |
| kms\_location                         | Terraform keyring location (use one documented here https://cloud.google.com/kms/docs/locations)       | `string`       | `"us"`  |    no    |
| project\_id                           | The ID of the project where this VPC will be created                                                   | `string`       | n/a     |   yes    |
| labels                                | Map of labels to put in resources                                                                      | `map(string)`  | `{}`    |    no    |
| service\_account\_id                  | Service account ID to manage tfstate and provide Terraform access to orchestrate resources             | `string`       | n/a     |   yes    |
| service\_account\_key\_rotation\_days | Number of days to set automatic key rotation for service account                                       | `number`       | `30`    |    no    |
| service\_account\_roles               | Service account roles (gcloud iam roles list)                                                          | `list(string)` | n/a     |   yes    |
| tfstate\_path                         | Remote path on GCS bucket to put terraform tfstate with remote backend                                 | `string`       | n/a     |   yes    |

## Outputs

| Name                          | Description                                                                                                                                                                 |
| ----------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| keyring                       | KMS keyring used to store tfstate bucket encryption key                                                                                                                     |
| service\_account              | Service Account to be used by terraform                                                                                                                                     |
| service\_account\_key         | Service Account key to be used as Google credential to orchestrate infrastructure                                                                                           |
| service\_account\_key\_object | This module saves the newly created service account key in the bucket used to store the tfstate, so this output value is a reference to the object storing json-encoded key |
| tfstate\_bucket               | Bucket created to be Terraform's backend                                                                                                                                    |
