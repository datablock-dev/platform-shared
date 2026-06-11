resource "aws_iam_user" "iam_user" {
  name          = "${var.iam_name}-${terraform.workspace}"
  force_destroy = true
}

resource "aws_iam_policy" "iam_user_policy" {
  name        = "${var.iam_name}-${var.iam_policy_name}-${terraform.workspace}"
  path        = "${var.iam_policy_path}"
  description = "${var.iam_policy_description}"

  policy = jsonencode({
    Version : "${var.iam_policy_version}",
    Statement : var.iam_policy_statements
  })
}

resource "aws_iam_user_policy_attachment" "iam_user_policy_attachment" {
  user       = aws_iam_user.iam_user.name
  policy_arn = aws_iam_policy.iam_user_policy.arn
}

resource "aws_iam_access_key" "iam_user_access_key" {
  count = var.create_access_key ? 1 : 0
  user = aws_iam_user.iam_user.name
}

resource "github_actions_secret" "aws_access_key_id" {
  count = (var.create_access_key && var.github_repository != "") ? 1 : 0

  repository      = var.github_repository
  secret_name     = var.aws_access_key_id_secret_name
  plaintext_value = aws_iam_access_key.iam_user_access_key[0].id
}

resource "github_actions_secret" "aws_secret_access_key" {
  count = (var.create_access_key && var.github_repository != "") ? 1 : 0

  repository      = var.github_repository
  secret_name     = var.aws_secret_access_key_secret_name
  plaintext_value = aws_iam_access_key.iam_user_access_key[0].secret
}