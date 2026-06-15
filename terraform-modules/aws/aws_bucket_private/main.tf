resource "aws_s3_bucket" "s3_bucket" {
  bucket        = "${var.bucket_name}-private-bucket-${terraform.workspace}"
  force_destroy = var.bucket_force_destroy

  tags = {
    Name        = "${var.bucket_name}"
    Environment = terraform.workspace
    ENV         = terraform.workspace
  }
}

resource "aws_iam_user" "bucket_access_user" {
  name          = "${var.bucket_name}-${var.iam_policy_name}-user-${terraform.workspace}"
  force_destroy = var.bucket_force_destroy
}

# IAM policy with access to the private bucket (for uploads)
resource "aws_iam_policy" "s3_bucket_policy" {
  name        = "${var.bucket_name}-${var.iam_policy_name}-policy-${terraform.workspace}"
  description = "Access to specific S3 bucket ${terraform.workspace}"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = var.iam_policy_statements != null ? var.iam_policy_statements : tolist([
      {
        Effect   = "Allow"
        Action   = ["s3:ListBucket"]
        Resource = [aws_s3_bucket.s3_bucket.arn]
      },
      {
        Effect   = "Allow"
        Action   = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject"
        ]
        Resource = ["${aws_s3_bucket.s3_bucket.arn}/*"]
      }
    ])
  })
}


resource "aws_iam_user_policy_attachment" "bucket_access_user_attach_s3_bucket_policy" {
  user       = aws_iam_user.bucket_access_user.name
  policy_arn = aws_iam_policy.s3_bucket_policy.arn
}