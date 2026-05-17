# Terraform Infrastructure for dukeofkherkeep.com

This directory contains Terraform configuration files to deploy the infrastructure for dukeofkherkeep.com.

## Overview

The infrastructure includes:
- S3 bucket for static website hosting
- CloudFront distribution with Origin Access Control
- Cloudflare DNS records
- API Gateway with Lambda function (optional)
- IAM roles and policies

## Prerequisites

1. AWS CLI installed and configured with appropriate credentials
2. Terraform installed (v1.5+)
3. Cloudflare account with API token
4. Domain registered and managed in Cloudflare

## Setup

1. Run the setup script:
   ```bash
   chmod +x setup.sh
   ./setup.sh
   ```

2. Review and update `terraform.tfvars` with your actual values

3. Initialize Terraform:
   ```bash
   terraform init
   ```

4. Plan the infrastructure:
   ```bash
   terraform plan
   ```

5. Apply the infrastructure:
   ```bash
   terraform apply
   ```

## Components

- `main.tf` - Main configuration entry point
- `providers.tf` - AWS and Cloudflare provider configuration
- `variables.tf` - Input variables
- `outputs.tf` - Output values
- `s3.tf` - S3 bucket configuration
- `cloudfront.tf` - CloudFront distribution configuration
- `dns.tf` - DNS records configuration
- `api_gateway.tf` - API Gateway and Lambda configuration
- `iam.tf` - IAM roles and policies
- `setup.sh` - Setup helper script
- `terraform.tfvars` - Variable values (not in repo)
- `terraform.tfvars.example` - Example variable values

## Security

- S3 bucket is private with CloudFront OAC
- CloudFront uses HTTPS with ACM certificate
- Basic auth function on CloudFront for admin access
- IAM roles with least privilege principle

## Cleanup

To destroy the infrastructure:
```bash
terraform destroy
```