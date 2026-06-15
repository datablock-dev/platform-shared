variable "name" {
  description = "Project name — used for OU name, account names, and email addresses"
  type        = string
}

variable "org_root_id" {
  description = "ID of the AWS Organizations root to attach the OU to"
  type        = string
}

variable "github_repo" {
  description = "GitHub repository name (without org prefix)"
  type        = string
}

variable "github_owner" {
  description = "GitHub organisation that owns the repository"
  type        = string
  default     = "datablock-dev"
}

variable "oidc_provider_arn" {
  description = "ARN of the shared GitHub Actions OIDC provider in the management account"
  type        = string
}
