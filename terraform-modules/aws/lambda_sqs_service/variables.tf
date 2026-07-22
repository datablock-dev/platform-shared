variable "service_name" {
  description = "Prefix for resource names"
  type        = string
}

variable "is_fifo" {
  description = "Whether the SQS queue is FIFO"
  default     = false
  type        = bool
}

variable "max_receive_count" {
  description = "Maximum number of times a message can be received before being sent to the dead-letter queue"
  default     = 1
  type        = number
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

variable "dead_letter_queue_arn" {
  description = "ARN of the dead-letter SQS queue"
  type        = string
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
    Action   = list(string)
    Resource = list(string)
  }))
}

variable "queue_policy_statements" {
  description = "Additional resource-policy statements granting other IAM principals access to the SQS queue. Resource is always this queue, so only Effect, Principal, and Action need to be set."
  default     = []
  type = list(object({
    Effect    = string
    Principal = any
    Action    = list(string)
  }))
}
