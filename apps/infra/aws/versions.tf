terraform {
  required_version = ">= 1.9.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    # Configure via backend config file or CLI:
    # terraform init \
    #   -backend-config="bucket=your-tfstate-bucket" \
    #   -backend-config="key=aws/terraform.tfstate" \
    #   -backend-config="region=ap-northeast-2" \
    #   -backend-config="dynamodb_table=your-tflock-table" \
    #   -backend-config="encrypt=true"
  }
}
