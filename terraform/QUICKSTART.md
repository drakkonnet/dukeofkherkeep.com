# Quick Start Guide - Terraform Infrastructure

## One-Time Setup

### 1. Navigate to Terraform Directory
```bash
cd terraform/
chmod +x setup.sh
./setup.sh
```

This script will:
- ✅ Check for required tools (terraform, aws, jq)
- ✅ Get your AWS Account ID
- ✅ Check for existing ACM certificate (or create one)
- ✅ Prompt for Cloudflare API token and Zone ID
- ✅ Create `terraform.tfvars` with all values
- ✅ Run `terraform init`

### 2. Review What Will Be Created
```bash
terraform plan
```

This shows all resources that will be created without making changes.

### 3. Deploy Infrastructure
```bash
terraform apply
```

Type `yes` when prompted. This will create:
- S3 bucket with CloudFront OAC
- CloudFront distribution
- API Gateway (optional)
- Lambda function (optional)
- IAM roles and policies
- Cloudflare DNS records

### 4. Verify Deployment
```bash
# Show all outputs
terraform output

# Test website
curl -I https://dukeofkherkeep.com/

# Check DNS
dig dukeofkherkeep.com +short
```

## Configuration Files

- `terraform.tfvars` - Your specific configuration values
- `terraform.tfvars.example` - Example values for reference

## Common Tasks

### Update Configuration
Edit `terraform.tfvars` and run:
```bash
terraform apply
```

### Add New Resources
1. Create new `.tf` files with resource definitions
2. Run `terraform plan` to see changes
3. Run `terraform apply` to implement changes

### Destroy Infrastructure
```bash
terraform destroy
```
Warning: This will delete all resources permanently.

## Troubleshooting

### State Locking Issues
If you see state locking errors:
```bash
# Force unlock (only if you're sure no one else is running Terraform)
terraform force-unlock LOCK_ID
```

### S3 Bucket Already Exists
If the S3 bucket already exists, you may need to import it:
```bash
terraform import aws_s3_bucket.website BUCKET_NAME
```

### ACM Certificate Validation
If your certificate is not validating:
1. Check the DNS validation records in the AWS console
2. Add the required DNS records to your domain
3. Wait for validation (can take up to 30 minutes)