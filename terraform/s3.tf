# S3 Bucket for website hosting
resource "aws_s3_bucket" "website" {
  provider = aws.us_east_1
  bucket   = "dukeofkherkeep-com-www"

  tags = merge(
    var.tags,
    {
      Name = "dukeofkherkeep-com-www"
    }
  )
}

# Block public access to the bucket
resource "aws_s3_bucket_public_access_block" "website" {
  provider = aws.us_east_1
  bucket   = aws_s3_bucket.website.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Enable versioning
resource "aws_s3_bucket_versioning" "website" {
  provider = aws.us_east_1
  bucket   = aws_s3_bucket.website.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Server-side encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "website" {
  provider = aws.us_east_1
  bucket   = aws_s3_bucket.website.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# S3 Bucket Policy for CloudFront OAC
data "aws_iam_policy_document" "s3_policy" {
  statement {
    sid = "AllowCloudFrontServicePrincipalReadOnly"

    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    actions = [
      "s3:GetObject"
    ]

    resources = [
      "${aws_s3_bucket.website.arn}/*"
    ]

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [aws_cloudfront_distribution.website.arn]
    }
  }
}

resource "aws_s3_bucket_policy" "website" {
  provider = aws.us_east_1
  bucket   = aws_s3_bucket.website.id
  policy   = data.aws_iam_policy_document.s3_policy.json
}