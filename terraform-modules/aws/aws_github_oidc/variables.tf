variable "repository" {
  description = "The repository in GitHub, owner included (e.g., datablock-dev/infrastructure)"
  type        = string

  validation {
    condition     = length(split("/", var.repository)) == 2
    error_message = "The repository must include the owner, e.g. datablock-dev/infrastructure."
  }
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
  description = "Extra IAM actions appended to the GitHub Actions ECR policy"
  default     = []
  type        = list(string)
}

# GitHub permanently switches a repository to immutable subject claims once it
# has been renamed or transferred, so its tokens carry numeric IDs instead of
# the current name. Check a repository with:
#   gh api repos/<owner>/<repo>/actions/oidc/customization/sub
variable "immutable_subject" {
  description = "Whether GitHub issues immutable (ID-based) OIDC subject claims for this repository"
  type        = bool
  default     = false
}

# Not read from the github provider: data.github_organization requires a token
# with read:user, which CI tokens rarely carry. The ID never changes, so a
# literal cannot drift. Find it with: gh api orgs/<owner> --jq .id
variable "owner_id" {
  description = "Immutable numeric ID of the GitHub owner. Required when immutable_subject is true"
  type        = number
  default     = null

  validation {
    condition     = !var.immutable_subject || var.owner_id != null
    error_message = "owner_id is required when immutable_subject is true."
  }
}

variable "terraform_state_bucket" {
  description = "S3 bucket holding Terraform state. Empty skips the state access policy entirely"
  type        = string
  default     = ""
}

variable "terraform_lock_table" {
  description = "DynamoDB table used for Terraform state locking. Empty grants no DynamoDB access"
  type        = string
  default     = ""
}
