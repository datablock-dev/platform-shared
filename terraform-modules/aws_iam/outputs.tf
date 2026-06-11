# IAM User Outputs
output "iam_user_name" {
  description = "The name of the IAM user"
  value       = aws_iam_user.iam_user.name
}

output "iam_user_arn" {
  description = "The ARN of the IAM user"
  value       = aws_iam_user.iam_user.arn
}

output "iam_user_unique_id" {
  description = "The unique ID assigned to the IAM user"
  value       = aws_iam_user.iam_user.unique_id
}

# IAM Policy Outputs
output "iam_policy_id" {
  description = "The ID of the IAM policy"
  value       = aws_iam_policy.iam_user_policy.id
}

output "iam_policy_arn" {
  description = "The ARN of the IAM policy"
  value       = aws_iam_policy.iam_user_policy.arn
}

output "iam_policy_name" {
  description = "The name of the IAM policy"
  value       = aws_iam_policy.iam_user_policy.name
}

output "access_key_id" {
  value = try(aws_iam_access_key.iam_user_access_key[0].id, null)
}

output "secret_access_key" {
  value     = try(aws_iam_access_key.iam_user_access_key[0].secret, null)
  sensitive = true
}