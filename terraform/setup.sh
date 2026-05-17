#!/usr/bin/env bash

# Terraform Setup Helper Script
# This script helps prepare the Terraform environment

DOMAIN="dukeofkherkeep.com"
REGION="us-east-1"
STATE_BUCKET="${DOMAIN//./-}-tf-state"
STATE_TABLE="${DOMAIN//./-}-terraform-locks"
TERRAFORM_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TFVARS_FILE="$TERRAFORM_DIR/terraform.tfvars"

# Force AWS region/profile for all AWS/Terraform calls
export AWS_PROFILE="duke"
export AWS_REGION="$REGION"
export AWS_DEFAULT_REGION="$REGION"

echo "=========================================="
echo "Terraform Infrastructure Setup Helper"
echo "=========================================="
echo ""

# Check for required tools
echo "Checking for required tools..."
for tool in terraform aws jq; do
  if ! command -v "$tool" &> /dev/null; then
    echo "❌ $tool not found. Please install it first."
    exit 1
  fi
done
echo "✓ All required tools found"
echo ""

# Get AWS Account ID
echo "Getting AWS Account ID..."
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
echo "✓ Account ID: $ACCOUNT_ID"
echo ""

# Ensure remote state bucket exists
echo "Checking Terraform state S3 bucket..."
echo "NOTE: If S3 API is slow, you may need to create the bucket manually:"
echo "  aws s3api create-bucket --bucket $STATE_BUCKET --region $REGION"
echo ""

# Use timeout to prevent hanging on slow S3 API calls and retry before creating
bucket_exists() {
  timeout 10 aws s3api head-bucket --bucket "$STATE_BUCKET" --region "$REGION" >/dev/null 2>&1
}

if bucket_exists; then
  echo "✓ State bucket $STATE_BUCKET already exists"
else
  echo "Creating state bucket $STATE_BUCKET..."
  if aws s3api create-bucket --bucket "$STATE_BUCKET" --region "$REGION" 2>/dev/null; then
    echo "✓ Created state bucket"
  else
    echo "⚠️  Failed to create state bucket. You may need to create it manually."
  fi
fi

# Enable versioning on state bucket
echo "Enabling versioning on state bucket..."
if aws s3api put-bucket-versioning --bucket "$STATE_BUCKET" --versioning-configuration Status=Enabled --region "$REGION" 2>/dev/null; then
  echo "✓ Enabled versioning on state bucket"
else
  echo "⚠️  Failed to enable versioning on state bucket"
fi

# Enable encryption on state bucket
echo "Enabling encryption on state bucket..."
if aws s3api put-bucket-encryption --bucket "$STATE_BUCKET" --server-side-encryption-configuration '{
  "Rules": [
    {
      "ApplyServerSideEncryptionByDefault": {
        "SSEAlgorithm": "AES256"
      }
    }
  ]
}' --region "$REGION" 2>/dev/null; then
  echo "✓ Enabled encryption on state bucket"
else
  echo "⚠️  Failed to enable encryption on state bucket"
fi

# Ensure DynamoDB table exists for state locking
echo "Checking Terraform state lock table..."
if aws dynamodb describe-table --table-name "$STATE_TABLE" --region "$REGION" >/dev/null 2>&1; then
  echo "✓ State lock table $STATE_TABLE already exists"
else
  echo "Creating state lock table $STATE_TABLE..."
  if aws dynamodb create-table \
    --table-name "$STATE_TABLE" \
    --attribute-definitions AttributeName=LockID,AttributeType=S \
    --key-schema AttributeName=LockID,KeyType=HASH \
    --billing-mode PAY_PER_REQUEST \
    --region "$REGION" 2>/dev/null; then
    echo "✓ Created state lock table"
    echo "Waiting for table to be active..."
    aws dynamodb wait table-exists --table-name "$STATE_TABLE" --region "$REGION"
  else
    echo "⚠️  Failed to create state lock table. You may need to create it manually."
  fi
fi

# Check for existing ACM certificate
echo ""
echo "Checking for existing ACM certificate..."
CERT_ARN=$(aws acm list-certificates --region us-east-1 --query "CertificateSummaryList[?DomainName=='$DOMAIN'].CertificateArn" --output text)

if [ -n "$CERT_ARN" ]; then
  echo "✓ Found existing certificate: $CERT_ARN"
else
  echo "Requesting new ACM certificate for $DOMAIN..."
  CERT_ARN=$(aws acm request-certificate \
    --domain-name "$DOMAIN" \
    --validation-method DNS \
    --region us-east-1 \
    --options CertificateTransparencyLoggingPreference=ENABLED \
    --query CertificateArn \
    --output text 2>/dev/null)
  
  if [ -n "$CERT_ARN" ]; then
    echo "✓ Requested new certificate: $CERT_ARN"
    echo "  You will need to validate it via DNS records."
    echo "  Run 'aws acm describe-certificate --certificate-arn $CERT_ARN --region us-east-1' to get validation details."
  else
    echo "⚠️  Failed to request certificate. You may need to do this manually."
  fi
fi

# Prompt for Cloudflare API token and Zone ID if not in tfvars
echo ""
echo "Checking for Cloudflare configuration..."
if [ ! -f "$TFVARS_FILE" ] || ! grep -q "cloudflare_api_token" "$TFVARS_FILE"; then
  echo "Please enter your Cloudflare API token (or leave blank to enter later):"
  read -r CLOUDFLARE_API_TOKEN
  
  echo "Please enter your Cloudflare Zone ID for $DOMAIN (or leave blank to enter later):"
  read -r CLOUDFLARE_ZONE_ID
  
  # Create terraform.tfvars if it doesn't exist
  if [ ! -f "$TFVARS_FILE" ]; then
    echo "Creating $TFVARS_FILE..."
    cat > "$TFVARS_FILE" <<EOF
# Terraform variables file
# Fill in actual values

aws_region = "$REGION"
environment = "production"
domain_name = "$DOMAIN"
account_id = "$ACCOUNT_ID"

# Get your AWS Account ID with: aws sts get-caller-identity --query Account --output text
account_id = "$ACCOUNT_ID"

# Cloudflare API Token: https://dash.cloudflare.com/profile/api-tokens
# Required permissions: Zone.Zone, Zone.DNS, Zone.Access (for DNS records)
cloudflare_api_token = "$CLOUDFLARE_API_TOKEN"

# Get Cloudflare Zone ID: https://dash.cloudflare.com/
cloudflare_zone_id = "$CLOUDFLARE_ZONE_ID"

# ARN of ACM certificate (must be in us-east-1 for CloudFront)
# Create with: aws acm request-certificate --domain-name $DOMAIN --validation-method DNS
acm_certificate_arn = "$CERT_ARN"

# Admin credentials for basic auth (change these!)
admin_username = "admin"
admin_password = "change-me"

# Set to true to create Route53 DNS records (if using Route53)
create_route53_records = false

# Enable API Gateway for /portfolio routes
enable_api_gateway = true
EOF
    echo "✓ Created $TFVARS_FILE"
  else
    echo "⚠️  $TFVARS_FILE already exists. Please update it with your values."
  fi
else
  echo "✓ Cloudflare configuration already in $TFVARS_FILE"
fi

# Initialize Terraform
echo ""
echo "Initializing Terraform..."
if terraform init; then
  echo "✓ Terraform initialized successfully"
else
  echo "⚠️  Terraform init failed. Please check your configuration."
fi

echo ""
echo "=========================================="
echo "Setup complete! Next steps:"
echo "1. Review terraform.tfvars and update with your values"
echo "2. Run 'terraform plan' to see what will be created"
echo "3. Run 'terraform apply' to create the infrastructure"
echo "=========================================="