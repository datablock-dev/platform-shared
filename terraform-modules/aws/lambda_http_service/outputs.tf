output "lambda_function_arn" {
  description = "ARN of the Lambda function"
  value       = aws_lambda_function.lambda.arn
}

output "lambda_function_name" {
  description = "Name of the Lambda function"
  value       = aws_lambda_function.lambda.function_name
}

output "sqs_queue_url" {
  description = "URL of the main service queue"
  value       = aws_sqs_queue.service_queue.url
}

output "sqs_queue_arn" {
  description = "ARN of the main service queue"
  value       = aws_sqs_queue.service_queue.arn
}
