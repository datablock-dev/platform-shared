# GitHub OIDC Provider for AWS
# This allows GitHub Actions to authenticate to AWS without storing credentials

# IAM Role that GitHub Actions will assume
resource "aws_iam_role" "github_actions" {
  name = "github-actions-${var.project_name}-${terraform.workspace}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = var.oidc_provider_arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
          StringLike = {
            # Restrict to your specific repository
            "token.actions.githubusercontent.com:sub" = "repo:${var.repository}:*"
          }
        }
      }
    ]
  })

  tags = {
    Name        = "github-actions-role"
    Environment = terraform.workspace
    ManagedBy   = "terraform"
  }
}

# Policy for ECR access
resource "aws_iam_policy" "github_actions_ecr" {
  name        = "github-actions-ecr-${var.project_name}-${terraform.workspace}"
  description = "Allows GitHub Actions to push/pull images to/from ECR"

  depends_on = [aws_iam_role.github_actions]

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = concat(var.policy, [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:PutImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload",
          "ecr:DescribeRepositories",
          "ecr:ListImages",
          "ecr:DescribeImages"
        ])
        Resource = "*"
      }
    ]
  })

  tags = {
    Name        = "github-actions-ecr-policy"
    Environment = terraform.workspace
    ManagedBy   = "terraform"
  }
}

# Attach ECR policy to the role
resource "aws_iam_role_policy_attachment" "github_actions_ecr" {
  role       = aws_iam_role.github_actions.name
  policy_arn = aws_iam_policy.github_actions_ecr.arn
}

# Optional: Add more policies as needed
# For example, if you need S3 access for Terraform state:
resource "aws_iam_policy" "github_actions_s3" {
  name        = "github-actions-s3-${var.project_name}-${terraform.workspace}"
  description = "Allows GitHub Actions to access S3 for Terraform state"

  depends_on = [aws_iam_policy.github_actions_ecr]

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:ListBucket",
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject"
        ]
        Resource = [
          "arn:aws:s3:::your-terraform-state-bucket",
          "arn:aws:s3:::your-terraform-state-bucket/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:DeleteItem"
        ]
        Resource = "arn:aws:dynamodb:*:*:table/your-terraform-lock-table"
      }
    ]
  })

  tags = {
    Name        = "github-actions-s3-policy"
    Environment = terraform.workspace
    ManagedBy   = "terraform"
  }
}

# Attach S3 policy to the role
resource "aws_iam_role_policy_attachment" "github_actions_s3" {
  role       = aws_iam_role.github_actions.name
  policy_arn = aws_iam_policy.github_actions_s3.arn
  
  depends_on = [aws_iam_policy.github_actions_s3]
}
