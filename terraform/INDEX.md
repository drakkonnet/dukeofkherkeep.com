# Terraform Infrastructure Documentation

## Overview

This directory contains Terraform configuration files to deploy the infrastructure for dukeofkherkeep.com.

## File Index

| File | Description |
|------|-------------|
| `api_gateway.tf` | API Gateway and Lambda function configuration |
| `cloudfront.tf` | CloudFront distribution with Origin Access Control |
| `dns.tf` | DNS records for Cloudflare and Route53 |
| `iam.tf` | IAM roles and policies |
| `main.tf` | Main configuration entry point |
| `outputs.tf` | Output values (URLs, IDs, etc.) |
| `providers.tf` | AWS and Cloudflare provider configuration |
| `s3.tf` | S3 bucket configuration |
| `variables.tf` | Input variables |
| `setup.sh` | Setup helper script |
| `terraform.tfvars.example` | Example configuration values |
| `README.md` | Infrastructure overview |
| `QUICKSTART.md` | Quick start guide |
| `SUMMARY.sh` | Setup summary |

## Quick Start

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

4. Plan and apply:
   ```bash
   terraform plan
   terraform apply
   ```

## Documentation

- [README.md](README.md) - Complete infrastructure overview
- [QUICKSTART.md](QUICKSTART.md) - Step-by-step setup guide
- [SUMMARY.sh](SUMMARY.sh) - Infrastructure summary

## Security

The infrastructure implements several security measures:
- Private S3 bucket with CloudFront OAC
- HTTPS encryption with ACM certificate
- Basic auth protection via CloudFront function
- IAM roles with least privilege principle