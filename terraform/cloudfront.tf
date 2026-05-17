# Origin Access Control for CloudFront to S3
locals {
  admin_basic_auth_header = "Basic ${base64encode("${var.admin_username}:${var.admin_password}")}"
}

resource "aws_cloudfront_origin_access_control" "s3_oac" {
  name                              = "${var.domain_name}-oac"
  description                       = "OAC for ${var.domain_name} CloudFront distribution"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"

  depends_on = [aws_s3_bucket.website]
}

resource "aws_cloudfront_function" "basic_auth" {
  # Function names cannot include dots; replace with dashes.
  name    = "${replace(var.domain_name, ".", "-")}-basic-auth"
  runtime = "cloudfront-js-1.0"

  code = <<-EOT
    function handler(event) {
      var req = event.request;
      var auth = req.headers.authorization && req.headers.authorization.value;
      var expected = "${local.admin_basic_auth_header}";

      if (auth === expected) {
        return req;
      }

      return {
        statusCode: 401,
        statusDescription: "Unauthorized",
        headers: {
          "www-authenticate": { value: 'Basic realm="Restricted"' },
          "content-type": { value: "text/plain" }
        },
        body: "Unauthorized"
      };
    }
  EOT
}

# CloudFront distribution
resource "aws_cloudfront_distribution" "website" {
  origin {
    domain_name              = aws_s3_bucket.website.bucket_regional_domain_name
    origin_id                = "S3Origin"
    origin_access_control_id = aws_cloudfront_origin_access_control.s3_oac.id
  }

  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"
  comment             = "CloudFront distribution for ${var.domain_name}"
  aliases             = [var.domain_name, "www.${var.domain_name}"]

  default_cache_behavior {
    allowed_methods        = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "S3Origin"
    compress               = true
    viewer_protocol_policy = "redirect-to-https"

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    # Apply basic auth function to viewer request
    function_association {
      event_type   = "viewer-request"
      function_arn = aws_cloudfront_function.basic_auth.arn
    }
  }

  ordered_cache_behavior {
    path_pattern     = "/api/*"
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "S3Origin"

    forwarded_values {
      query_string = true

      cookies {
        forward = "all"
      }
    }

    compress               = true
    viewer_protocol_policy = "https-only"
  }

  price_class = "PriceClass_100"

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn      = var.acm_certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.domain_name}-cloudfront"
    }
  )
}