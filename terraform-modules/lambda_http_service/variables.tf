variable "service_name" {
  description = "Prefix for resource names"
  type        = string
}

variable "is_fifo" {
  description = "Whether the SQS queue is FIFO"
  default     = false
  type        = bool
}

variable "lambda_handler" {
  description = "Lambda function handler"
  default     = "index.handler"
  type        = string
}

variable "lambda_runtime" {
  description = "Runtime for Lambda function"
  default     = "nodejs22.x"
  type        = string
}

variable "lambda_timeout" {
  description = "Timeout for Lambda"
  default     = 10
  type        = number
}

variable "env_variables" {
  description = "Map of environment variables to pass to the Lambda function"
  type        = map(string)
}

variable "additional_iam_statements" {
  description = "Additional IAM policy statements"
  default     = []
  type = list(object({
    Effect   = string
    Action   = any
    Resource = any
  }))
}
