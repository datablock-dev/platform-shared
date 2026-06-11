# S3 Bucket Outputs
output "bucket_id" {
  description = "The name of the S3 bucket"
  value       = aws_s3_bucket.public_bucket.id
}

output "bucket_arn" {
  description = "The ARN of the S3 bucket"
  value       = aws_s3_bucket.public_bucket.arn
}

output "bucket_regional_domain_name" {
  description = "The regional domain name of the S3 bucket"
  value       = aws_s3_bucket.public_bucket.bucket_regional_domain_name
}

# CloudFront Distribution Outputs
output "cloudfront_distribution_id" {
  description = "The ID of the CloudFront distribution"
  value       = aws_cloudfront_distribution.cdn.id
}

output "cloudfront_distribution_arn" {
  description = "The ARN of the CloudFront distribution"
  value       = aws_cloudfront_distribution.cdn.arn
}

output "cloudfront_domain_name" {
  description = "The domain name of the CloudFront distribution"
  value       = aws_cloudfront_distribution.cdn.domain_name
}

output "cloudfront_hosted_zone_id" {
  description = "The CloudFront Route 53 zone ID"
  value       = aws_cloudfront_distribution.cdn.hosted_zone_id
}

# IAM User Outputs
output "iam_user_name" {
  description = "The name of the IAM user"
  value       = aws_iam_user.bucket_access_user.name
}

output "iam_user_arn" {
  description = "The ARN of the IAM user"
  value       = aws_iam_user.bucket_access_user.arn
}

# IAM Policy Outputs
output "iam_policy_arn" {
  description = "The ARN of the IAM policy for S3 bucket access"
  value       = aws_iam_policy.public_s3_bucket_policy.arn
}

output "iam_policy_id" {
  description = "The ID of the IAM policy for S3 bucket access"
  value       = aws_iam_policy.public_s3_bucket_policy.id
}

# Origin Access Control Output
output "cloudfront_oac_id" {
  description = "The ID of the CloudFront Origin Access Control"
  value       = aws_cloudfront_origin_access_control.oac.id
}
