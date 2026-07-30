# Outputs for GitHub Actions workflows
output "role_arn" {
  description = "ARN of the IAM role GitHub Actions assumes — set this as the OIDC_ROLE_ARN repository variable"
  value       = aws_iam_role.github_actions.arn
}

output "role_name" {
  description = "Name of the IAM role, for attaching further policies from the caller"
  value       = aws_iam_role.github_actions.name
}

output "subject_claim" {
  description = "The sub claim pattern the trust policy matches, useful for debugging failed AssumeRoleWithWebIdentity calls"
  value       = local.subject_claim
}
