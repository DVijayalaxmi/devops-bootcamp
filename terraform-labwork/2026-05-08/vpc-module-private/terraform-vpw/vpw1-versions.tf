# Terraform Block
terraform {
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
  # Remote Backend
  backend "s3" {
    bucket = "tfstate-dev-ap-south-1-0exnf3-vpw"
    key = "vpc/dev/terraform.tfstate"
    region = "ap-south-1"
    encrypt = true
    use_lockfile = true
  }
}


# Provider Block
provider "aws" {
  region = var.aws_region
}
