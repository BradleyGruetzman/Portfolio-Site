variable "aws_region" {
  description = "AWS region for provider"
  type        = string
  default     = "us-east-1"
}

variable "bucket_name" {
  description = "Globally unique S3 bucket name for the portfolio"
  type        = string
  # change this to a unique name (no uppercase or spaces)
  default     = "brad-portfolio-site-123-unique"
}

# basic mime type mapping; you can extend this
variable "content_types" {
  type = map(string)
  default = {
    html = "text/html; charset=utf-8"
    css  = "text/css; charset=utf-8"
    js   = "application/javascript; charset=utf-8"
    png  = "image/png"
    jpg  = "image/jpeg"
    jpeg = "image/jpeg"
    svg  = "image/svg+xml"
    ico  = "image/x-icon"
    json = "application/json"
    txt  = "text/plain"
  }
}

variable "domain_name" {
  description = "Custom domain for the portfolio site"
  type        = string
}