variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "production"
}

variable "domain_name" {
  description = "Domain name for the website"
  type        = string
  default     = "dukeofkherkeep.com"
}

variable "account_id" {
  description = "AWS Account ID"
  type        = string
}

variable "cloudflare_api_token" {
  description = "Cloudflare API token"
  type        = string
  sensitive   = true
}

variable "cloudflare_zone_id" {
  description = "Cloudflare Zone ID for the domain"
  type        = string
  sensitive   = true
}

variable "acm_certificate_arn" {
  description = "ARN of the ACM certificate for the domain"
  type        = string
}

variable "enable_api_gateway" {
  description = "Enable API Gateway for /portfolio routes"
  type        = bool
  default     = true
}

variable "lambda_function_name" {
  description = "Name of the Lambda function"
  type        = string
  default     = "portfolio-api"
}

variable "admin_username" {
  description = "Username for admin basic auth"
  type        = string
  default     = "admin"
}

variable "admin_password" {
  description = "Password for admin basic auth"
  type        = string
  sensitive   = true
}

variable "create_route53_records" {
  description = "Create Route53 DNS records"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default = {
    Environment = "production"
    Project     = "dukeofkherkeep-com"
  }
}