variable "repository" {
    description = "The name of the repository in GitHub (e.g., datablock-dev/infrastructure)"
    type        = string
}

variable "project_name" {
    description = "Project name to create unique resource names (e.g., datablock, emberbill)"
    type        = string
}

variable "oidc_provider_arn" {
    description = "ARN of the GitHub OIDC provider"
    type        = string
}

variable "policy" {
    description = "The IAM policy document for the GitHub Actions role"
    default     = []
    type        = list(string)
}