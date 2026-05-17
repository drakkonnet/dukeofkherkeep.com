# Cloudflare DNS records pointing to CloudFront

# Root domain (www) - CNAME to CloudFront
resource "aws_route53_record" "cf_cname" {
  count   = var.create_route53_records ? 1 : 0
  zone_id = data.aws_route53_zone.main[0].zone_id
  name    = "www.${var.domain_name}"
  type    = "CNAME"
  ttl     = 300
  records = [aws_cloudfront_distribution.website.domain_name]
}

# Apex domain - A record to CloudFront (using alias)
resource "aws_route53_record" "cf_root" {
  count   = var.create_route53_records ? 1 : 0
  zone_id = data.aws_route53_zone.main[0].zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.website.domain_name
    zone_id                = aws_cloudfront_distribution.website.hosted_zone_id
    evaluate_target_health = false
  }
}

# Get existing Route53 zone
data "aws_route53_zone" "main" {
  count = var.create_route53_records ? 1 : 0
  name  = var.domain_name
}

# Cloudflare DNS records
resource "cloudflare_record" "root" {
  zone_id = var.cloudflare_zone_id
  name    = var.domain_name
  value   = aws_cloudfront_distribution.website.domain_name
  type    = "CNAME"
  proxied = true
  ttl     = 1
}

resource "cloudflare_record" "www" {
  zone_id = var.cloudflare_zone_id
  name    = "www.${var.domain_name}"
  value   = aws_cloudfront_distribution.website.domain_name
  type    = "CNAME"
  proxied = true
  ttl     = 1
}