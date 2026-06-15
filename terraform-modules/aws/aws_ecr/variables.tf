variable "name" {
  description = "Name of the ECR repository"
  type        = string
}

variable "count_number" {
  description = "Number of images to keep in the lifecycle policy"
  type        = number
  default     = 5
}

variable "count_type" {
  description = "Type of count for the lifecycle policy (e.g., imageCountMoreThan)"
  type        = string
  default     = "imageCountMoreThan"
}

variable "tag_status" {
  description = "Tag status for the lifecycle policy (e.g., any, tagged, untagged)"
  type        = string
  default     = "any"
}

variable "mutability" {
  description = "Image tag mutability setting"
  type        = string
  default     = "MUTABLE"
}

variable "tags" {
  description = "Tags to apply to the ECR repository"
  type        = map(string)
  default     = {}
}