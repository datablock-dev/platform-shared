variable "bucket_name" {
  description = "Prefix for the S3 bucket name"
  type        = string
}

variable "bucket_force_destroy" {
  description = "Whether to force destroy the bucket (delete all objects when destroying)"
  default     = true
  type        = bool
}

variable "iam_policy_name" {
  description = "Name for the IAM policy allowing public read access"
  default     = "policy-access"
  type        = string
}

variable "iam_policy_statements" {
  description = "Additional statements to include in the S3 bucket policy (as JSON)"
  default     = null
  type        = list(object({
      Effect   = string
      Action   = list(string)
      Resource = list(string)
  }))
}