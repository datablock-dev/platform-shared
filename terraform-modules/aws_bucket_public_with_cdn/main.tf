resource "aws_s3_bucket" "public_bucket" {
  bucket        = "${var.bucket_name}-public-bucket-${terraform.workspace}"
  force_destroy = true

  tags = {
    Name        = "${var.bucket_name}"
    Environment = terraform.workspace
    ENV         = terraform.workspace
  }
}

resource "aws_s3_bucket_public_access_block" "public_block" {
  bucket   = aws_s3_bucket.public_bucket.id

  block_public_acls       = true
  block_public_policy     = false  # Must be false to allow bucket policy
  ignore_public_acls      = true
  restrict_public_buckets = false  # Must be false to allow CloudFront access
}

# Origin Access Control (replaces OAI)
resource "aws_cloudfront_origin_access_control" "oac" {
  name                              = "${var.bucket_name}-public-bucket-oac-${terraform.workspace}"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
  description                       = "OAC for CloudFront -> S3"
}

# CloudFront Distribution
resource "aws_cloudfront_distribution" "cdn" {
  enabled         = true
  is_ipv6_enabled = true

  origin {
    domain_name = aws_s3_bucket.public_bucket.bucket_regional_domain_name
    origin_id   = "public-s3-origin"

    origin_access_control_id = aws_cloudfront_origin_access_control.oac.id
  }

  default_cache_behavior {
    allowed_methods            = ["GET", "HEAD", "OPTIONS"]
    cached_methods             = ["GET", "HEAD"]
    target_origin_id           = "public-s3-origin"
    viewer_protocol_policy     = "redirect-to-https"
    compress                   = true
    response_headers_policy_id = aws_cloudfront_response_headers_policy.cors_policy.id

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    min_ttl     = 0
    default_ttl = 3600
    max_ttl     = 86400
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  tags = {
    Name = "Public CDN for Files"
  }
}

# CORS Response Headers Policy for CloudFront
resource "aws_cloudfront_response_headers_policy" "cors_policy" {
  name = "${var.bucket_name}-cors-policy-${terraform.workspace}"

  cors_config {
    access_control_allow_credentials = false

    access_control_allow_headers {
      items = var.cors_allowed_headers
    }

    access_control_allow_methods {
      items = var.cors_allowed_methods
    }

    access_control_allow_origins {
      items = var.cors_allowed_origins
    }

    access_control_max_age_sec = var.cors_max_age_seconds
    origin_override            = true
  }
}

# Allow CloudFront access to public bucket
resource "aws_s3_bucket_policy" "public_policy" {
  bucket   = aws_s3_bucket.public_bucket.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCloudFrontServicePrincipal"
        Effect = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Action   = "s3:GetObject"
        Resource = "${aws_s3_bucket.public_bucket.arn}/*"
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = aws_cloudfront_distribution.cdn.arn
          }
        }
      }
    ]
  })
}

resource "aws_s3_bucket_cors_configuration" "bucket_cors" {
  bucket = aws_s3_bucket.public_bucket.id

  cors_rule {
    allowed_headers = var.cors_allowed_headers
    allowed_methods = var.cors_allowed_methods
    allowed_origins = var.cors_allowed_origins
    expose_headers  = var.cors_expose_headers
    max_age_seconds = var.cors_max_age_seconds
  }
}

/*
    IAM User to access the S3 bucket

*/


resource "aws_iam_user" "bucket_access_user" {
  name          = "${var.bucket_name}-${var.iam_policy_name}-user-${terraform.workspace}"
  force_destroy = true
}

# IAM policy with access to the public bucket (for uploads)
resource "aws_iam_policy" "public_s3_bucket_policy" {
  name        = "${var.bucket_name}-${var.iam_policy_name}-policy-${terraform.workspace}"
  description = "Access to specific S3 bucket ${terraform.workspace}"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:ListBucket"
        ]
        Resource = aws_s3_bucket.public_bucket.arn  # Without /*
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject"
        ]
        Resource = "${aws_s3_bucket.public_bucket.arn}/*"
      }
    ]
  })
}

resource "aws_iam_user_policy_attachment" "bucket_access_user_attach_public_s3_bucket_policy" {
  user       = aws_iam_user.bucket_access_user.name
  policy_arn = aws_iam_policy.public_s3_bucket_policy.arn
}