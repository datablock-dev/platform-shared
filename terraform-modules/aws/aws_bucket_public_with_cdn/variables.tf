variable "bucket_name" {
  description = "Prefix for the S3 bucket name"
  type        = string
}

variable "cors_allowed_methods" {
    description = "CORS configuration for the S3 bucket"
    type = list(string)
    default = ["GET", "PUT", "POST", "HEAD"]
}

variable "cors_allowed_origins" {
    type = list(string)
}

variable "cors_allowed_headers" {
    description = "CORS Allowed Headers"
    type = list(string)
    default = ["*"]
}

variable "cors_expose_headers" {
    description = "CORS Expose Headers"
    default = ["ETag", "Content-Length"]
    type = list(string)
}

variable "cors_max_age_seconds" {
    description = "CORS Max Age in seconds"
    type = number
    default = 600
}

variable "iam_policy_name" {
  description = "Name for the IAM policy allowing public read access"
  default     = "policy-access"
  type        = string
}