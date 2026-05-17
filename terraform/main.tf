# Main Terraform configuration
# This file imports all the infrastructure components

# CloudFront distribution ID
locals {
  distribution_id = aws_cloudfront_distribution.website.id
  bucket_name     = aws_s3_bucket.website.id
}