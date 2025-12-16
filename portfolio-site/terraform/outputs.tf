output "s3_bucket_name" {
  description = "Name of the S3 bucket"
  value       = aws_s3_bucket.portfolio.bucket
}

output "cloudfront_domain" {
  description = "CloudFront domain to access the site"
  value       = aws_cloudfront_distribution.cdn.domain_name
}

output "cloudfront_id" {
  description = "CloudFront distribution id"
  value       = aws_cloudfront_distribution.cdn.id
}