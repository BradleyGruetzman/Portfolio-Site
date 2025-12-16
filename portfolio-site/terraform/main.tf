terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.0"
    }
  }
  required_version = ">= 1.2.0"
}

# Default provider (S3, CloudFront, Route53)
provider "aws" {
  region = var.aws_region
}

# us-east-1 provider (ACM MUST be here for CloudFront)
provider "aws" {
  alias  = "use1"
  region = "us-east-1"
}

# -----------------------
# Local helpers
# -----------------------
locals {
  site_files = fileset("${path.module}/../website", "**")

  file_extensions = {
    for f in local.site_files :
    f => lower(element(split(".", f), length(split(".", f)) - 1))
  }

  content_type_by_file = {
    for f, ext in local.file_extensions :
    f => lookup(var.content_types, ext, "binary/octet-stream")
  }
}

# -----------------------
# S3 Bucket (PRIVATE)
# -----------------------
resource "aws_s3_bucket" "portfolio" {
  bucket = var.bucket_name

  tags = {
    Name = "portfolio-site"
    Env  = "prod"
  }
}

resource "aws_s3_bucket_versioning" "portfolio" {
  bucket = aws_s3_bucket.portfolio.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "block" {
  bucket = aws_s3_bucket.portfolio.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# -----------------------
# Upload website files
# -----------------------
resource "aws_s3_object" "site_files" {
  for_each = { for f in local.site_files : f => f }

  bucket       = aws_s3_bucket.portfolio.id
  key          = each.key
  source       = "${path.module}/../website/${each.value}"
  etag         = filemd5("${path.module}/../website/${each.value}")
  content_type = local.content_type_by_file[each.value]
  acl          = "private"
}

# -----------------------
# CloudFront OAI
# -----------------------
resource "aws_cloudfront_origin_access_identity" "oai" {
  comment = "OAI for ${aws_s3_bucket.portfolio.bucket}"
}

# -----------------------
# Bucket policy (CloudFront ONLY)
# -----------------------
resource "aws_s3_bucket_policy" "allow_cf" {
  bucket = aws_s3_bucket.portfolio.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCloudFrontRead"
        Effect = "Allow"
        Principal = {
          CanonicalUser = aws_cloudfront_origin_access_identity.oai.s3_canonical_user_id
        }
        Action   = ["s3:GetObject"]
        Resource = "${aws_s3_bucket.portfolio.arn}/*"
      }
    ]
  })
}

# -----------------------
# Route53 Hosted Zone (EXISTING)
# -----------------------
data "aws_route53_zone" "main" {
  name         = var.domain_name
  private_zone = false
}

# -----------------------
# ACM Certificate (us-east-1)
# -----------------------
resource "aws_acm_certificate" "cert" {
  provider          = aws.use1
  domain_name       = var.domain_name
  validation_method = "DNS"
}

resource "aws_route53_record" "cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.cert.domain_validation_options :
    dvo.domain_name => {
      name  = dvo.resource_record_name
      type  = dvo.resource_record_type
      value = dvo.resource_record_value
    }
  }

  zone_id = data.aws_route53_zone.main.zone_id
  name    = each.value.name
  type    = each.value.type
  records = [each.value.value]
  ttl     = 60
}

resource "aws_acm_certificate_validation" "cert" {
  provider                = aws.use1
  certificate_arn         = aws_acm_certificate.cert.arn
  validation_record_fqdns = [for r in aws_route53_record.cert_validation : r.fqdn]
}

# -----------------------
# CloudFront Distribution
# -----------------------
resource "aws_cloudfront_distribution" "cdn" {
  enabled             = true
  default_root_object = "index.html"

  aliases = [
    var.domain_name
  ]

  origin {
    domain_name = aws_s3_bucket.portfolio.bucket_regional_domain_name
    origin_id   = "s3-${aws_s3_bucket.portfolio.id}"

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.oai.cloudfront_access_identity_path
    }
  }

  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "s3-${aws_s3_bucket.portfolio.id}"
    viewer_protocol_policy = "redirect-to-https"

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate.cert.arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  tags = {
    Name = "portfolio-cdn"
  }
}

# -----------------------
# DNS → CloudFront
# -----------------------
resource "aws_route53_record" "root_domain" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.cdn.domain_name
    zone_id                = aws_cloudfront_distribution.cdn.hosted_zone_id
    evaluate_target_health = false
  }
}


