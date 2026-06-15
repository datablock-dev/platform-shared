variable "iam_name" {
    description = "Name for the IAM user"
    type        = string
}

variable "iam_policy_name" {
    description = "Name for the IAM policy"
    type        = string
    default     = "policy"
}

variable "iam_policy_statements" {
    description = "List of IAM policy statements"
    type = list(object({
        Effect   = string
        Action   = list(string)
        Resource = list(string)
    }))
}

variable "iam_policy_path" {
    description = "Path for the IAM policy"
    type        = string
    default     = "/"
}

variable "iam_policy_description" {
    description = "Description for the IAM policy"
    type        = string
    default     = ""
}

variable "iam_policy_version" {
    description = "Version of the IAM policy"
    type        = string
    default     = "2012-10-17"
}

variable "create_access_key" {
    description = "Whether to create an access key for the IAM user"
    type        = bool
    default     = false
}

variable "github_repository" {
    description = "GitHub repository to push AWS credentials to (empty = skip)"
    type        = string
    default     = ""
}

variable "aws_access_key_id_secret_name" {
    description = "Name of the GitHub Actions secret for the AWS access key ID"
    type        = string
    default     = "AWS_ACCESS_KEY_ID"
}

variable "aws_secret_access_key_secret_name" {
    description = "Name of the GitHub Actions secret for the AWS secret access key"
    type        = string
    default     = "AWS_SECRET_ACCESS_KEY"
}