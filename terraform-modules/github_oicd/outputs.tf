# Outputs for GitHub Actions workflows
output "datablock_github_oidc_role_arn" {
  description = "ARN of the IAM role for datablock GitHub Actions"
  value       = aws_iam_role.github_actions.arn
}