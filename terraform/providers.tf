terraform {
  required_version = ">= 1.5.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 4.0"
    }
  }

  backend "s3" {
    bucket         = "dukeofkherkeep-com-tf-state"
    key            = "terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "dukeofkherkeep-com-terraform-locks"
  }
}

# AWS Provider - US East 1 (for CloudFront & Route53)
provider "aws" {
  region = var.aws_region
  alias  = "us_east_1"

  default_tags {
    tags = var.tags
  }
}

# AWS Provider - Default region
provider "aws" {
  region = var.aws_region

  default_tags {
    tags = var.tags
  }
}

# Cloudflare Provider
provider "cloudflare" {
  api_token = var.cloudflare_api_token
}