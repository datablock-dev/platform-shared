# GitHub OIDC role for AWS
# This allows GitHub Actions to authenticate to AWS without storing credentials

# Only read when immutable subject claims are in play — the plain-name subject
# needs no lookup, which keeps a GitHub API call (and the github provider) off
# the path for callers that do not need it.
data "github_repository" "this" {
  count     = var.immutable_subject ? 1 : 0
  full_name = var.repository
}

locals {
  owner     = split("/", var.repository)[0]
  repo_name = split("/", var.repository)[1]

  # GitHub permanently switches a repository to immutable subject claims once it
  # has been renamed or transferred: the sub becomes
  # repo:<owner>@<owner_id>/<repo>@<repo_id>:<context> rather than
  # repo:<owner>/<repo>:<context>. The IDs are what let the claim survive a
  # rename, and they also stop a newly created repo that squats the freed-up old
  # name from inheriting this role's trust. Matching one form only is deliberate:
  # accepting the plain name as well would reopen exactly that squatting window.
  subject_claim = var.immutable_subject ? "repo:${local.owner}@${var.owner_id}/${local.repo_name}@${data.github_repository.this[0].repo_id}:*" : "repo:${var.repository}:*"

  manage_state_access = var.terraform_state_bucket != ""

  terraform_state_statements = concat(
    [
      {
        Effect = "Allow"
        Action = [
          "s3:ListBucket",
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
        ]
        Resource = [
          "arn:aws:s3:::${var.terraform_state_bucket}",
          "arn:aws:s3:::${var.terraform_state_bucket}/*",
        ]
      }
    ],
    var.terraform_lock_table == "" ? [] : [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:DeleteItem",
        ]
        Resource = "arn:aws:dynamodb:*:*:table/${var.terraform_lock_table}"
      }
    ],
  )
}

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
            # Restrict to the specific repository
            "token.actions.githubusercontent.com:sub" = local.subject_claim
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

resource "aws_iam_role_policy_attachment" "github_actions_ecr" {
  role       = aws_iam_role.github_actions.name
  policy_arn = aws_iam_policy.github_actions_ecr.arn
}

# Terraform state access, created only when the caller names a bucket. The
# bucket and lock table have to come from the caller: a shared module cannot
# know them, and the placeholder ARNs this module used to hardcode granted
# access to nothing while still attaching a policy that looked meaningful.
resource "aws_iam_policy" "github_actions_state" {
  count = local.manage_state_access ? 1 : 0

  name        = "github-actions-s3-${var.project_name}-${terraform.workspace}"
  description = "Allows GitHub Actions to read and write Terraform state"

  policy = jsonencode({
    Version   = "2012-10-17"
    Statement = local.terraform_state_statements
  })

  tags = {
    Name        = "github-actions-s3-policy"
    Environment = terraform.workspace
    ManagedBy   = "terraform"
  }
}

resource "aws_iam_role_policy_attachment" "github_actions_state" {
  count = local.manage_state_access ? 1 : 0

  role       = aws_iam_role.github_actions.name
  policy_arn = aws_iam_policy.github_actions_state[0].arn
}
