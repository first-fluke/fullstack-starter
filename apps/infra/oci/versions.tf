terraform {
  # The native OCI state backend requires Terraform >= 1.12.0 (the other
  # stacks pin >= 1.9.0; Oracle deprecated the S3-compatible Object Storage
  # backend in favor of `backend "oci"` — see README Notes).
  required_version = ">= 1.12.0"

  required_providers {
    oci = {
      source  = "oracle/oci"
      version = "~> 8.0"
    }
  }

  backend "oci" {
    # Native OCI Object Storage backend (Terraform >= 1.12).
    # Configure via backend config file or CLI:
    # terraform init \
    #   -backend-config="bucket=your-tfstate-bucket" \
    #   -backend-config="namespace=your-objectstorage-namespace" \
    #   -backend-config="key=oci/terraform.tfstate" \
    #   -backend-config="region=ap-seoul-1" \
    #   -backend-config="config_file_profile=DEFAULT"
  }
}
