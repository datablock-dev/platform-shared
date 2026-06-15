# S3 Bucket Outputs
output "bucket_id" {
  description = "The name of the S3 bucket"
  value       = aws_s3_bucket.s3_bucket.id
}

output "bucket_arn" {
  description = "The ARN of the S3 bucket"
  value       = aws_s3_bucket.s3_bucket.arn
}

output "bucket_regional_domain_name" {
  description = "The regional domain name of the S3 bucket"
  value       = aws_s3_bucket.s3_bucket.bucket_regional_domain_name
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
  value       = aws_iam_policy.s3_bucket_policy.arn
}

output "iam_policy_id" {
  description = "The ID of the IAM policy for S3 bucket access"
  value       = aws_iam_policy.s3_bucket_policy.id
}