terraform {
  required_version = ">= 1.9.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 8.0"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "~> 8.0"
    }
  }

  backend "gcs" {
    # Configure via backend config file or CLI:
    # terraform init -backend-config="bucket=your-tfstate-bucket"
  }
}
