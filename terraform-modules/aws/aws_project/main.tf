resource "aws_organizations_organizational_unit" "this" {
  name      = var.name
  parent_id = var.org_root_id
}

resource "aws_organizations_account" "this" {
  for_each = toset(["staging", "production"])

  name      = "${var.name}-${each.key}"
  email     = "aws+${var.name}-${each.key}@datablock.dev"
  parent_id = aws_organizations_organizational_unit.this.id
  role_name = "OrganizationAccountAccessRole"

  lifecycle {
    ignore_changes = [email, name]
  }
}

# Bootstrap a Terraform state bucket in each child account on account creation.
# Bucket name is deterministic so repos can hardcode it in their backend config.
resource "terraform_data" "state_bucket" {
  for_each = toset(["staging", "production"])

  input = aws_organizations_account.this[each.key].id

  provisioner "local-exec" {
    command = <<-EOT
      set -e
      ACCOUNT_ID="${aws_organizations_account.this[each.key].id}"
      BUCKET="do-not-delete-terraform-${var.name}-${each.key}"
      REGION="eu-north-1"

      CREDS=$(aws sts assume-role \
        --role-arn "arn:aws:iam::$ACCOUNT_ID:role/OrganizationAccountAccessRole" \
        --role-session-name "tf-state-bootstrap")

      export AWS_ACCESS_KEY_ID=$(echo "$CREDS"     | jq -r .Credentials.AccessKeyId)
      export AWS_SECRET_ACCESS_KEY=$(echo "$CREDS" | jq -r .Credentials.SecretAccessKey)
      export AWS_SESSION_TOKEN=$(echo "$CREDS"     | jq -r .Credentials.SessionToken)

      aws s3api create-bucket \
        --bucket "$BUCKET" \
        --region "$REGION" \
        --create-bucket-configuration LocationConstraint="$REGION" 2>/dev/null || true

      aws s3api put-bucket-versioning \
        --bucket "$BUCKET" --region "$REGION" \
        --versioning-configuration Status=Enabled

      aws s3api put-bucket-encryption \
        --bucket "$BUCKET" --region "$REGION" \
        --server-side-encryption-configuration \
          '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"},"BucketKeyEnabled":true}]}'

      aws s3api put-public-access-block \
        --bucket "$BUCKET" --region "$REGION" \
        --public-access-block-configuration \
          "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"
    EOT
  }
}

module "github_oidc" {
  source = "../github_oicd"

  repository        = "${var.github_owner}/${var.github_repo}"
  project_name      = var.name
  oidc_provider_arn = var.oidc_provider_arn
}

resource "aws_iam_role_policy" "cross_account" {
  name = "cross-account-assume"
  role = module.github_oidc.role_name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = "sts:AssumeRole"
      Resource = [
        "arn:aws:iam::${aws_organizations_account.this["staging"].id}:role/OrganizationAccountAccessRole",
        "arn:aws:iam::${aws_organizations_account.this["production"].id}:role/OrganizationAccountAccessRole",
      ]
    }]
  })
}

resource "github_actions_variable" "staging_account_id" {
  repository    = var.github_repo
  variable_name = "AWS_STAGING_ACCOUNT_ID"
  value         = aws_organizations_account.this["staging"].id
}

resource "github_actions_variable" "production_account_id" {
  repository    = var.github_repo
  variable_name = "AWS_PRODUCTION_ACCOUNT_ID"
  value         = aws_organizations_account.this["production"].id
}

resource "github_actions_variable" "oidc_role_arn" {
  repository    = var.github_repo
  variable_name = "OIDC_ROLE_ARN"
  value         = module.github_oidc.role_arn
}
