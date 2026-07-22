locals {
  fifo_suffix = var.is_fifo ? ".fifo" : ""
}

resource "aws_sqs_queue" "service_queue" {
  name                        = "${terraform.workspace}-${var.service_name}-sqs-queue${local.fifo_suffix}"
  delay_seconds               = 0
  fifo_queue                  = var.is_fifo
  content_based_deduplication = var.is_fifo
  max_message_size            = 262144
  message_retention_seconds   = 345600
  receive_wait_time_seconds   = 0

  redrive_policy = jsonencode({
    deadLetterTargetArn = var.dead_letter_queue_arn
    maxReceiveCount     = var.max_receive_count
  })
}

resource "aws_iam_role" "lambda_role" {
  name = "${terraform.workspace}-${var.service_name}-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "lambda.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "lambda_policy" {
  name = "${terraform.workspace}-${var.service_name}-lambda-policy"
  role = aws_iam_role.lambda_role.name

  policy = jsonencode({
    Version : "2012-10-17",
    Statement : concat([
      {
        Effect : "Allow",
        Action : [
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes"
        ],
        Resource : [
          aws_sqs_queue.service_queue.arn,
          var.dead_letter_queue_arn
        ]
      },
      {
        Effect : "Allow"
        Action : [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams"
        ]
        Resource : "*"
      }
    ], var.additional_iam_statements)
  })
}

#####################################
# Lambda Function
#####################################

data "archive_file" "notifications_placeholder" {
  type        = "zip"
  output_path = "${path.module}/placeholder-notifications.zip"
  source {
    content  = "exports.handler = async () => ({ statusCode: 200, body: 'placeholder' })"
    filename = "index.js"
  }
}

resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_lambda_function" "lambda" {
  function_name    = "${terraform.workspace}-${var.service_name}-lambda"
  handler          = var.lambda_handler
  runtime          = var.lambda_runtime
  architectures    = ["arm64"]
  role             = aws_iam_role.lambda_role.arn
  filename         = data.archive_file.notifications_placeholder.output_path
  source_code_hash = data.archive_file.notifications_placeholder.output_base64sha256
  publish          = true
  timeout          = var.lambda_timeout
  memory_size      = 512

  environment {
    variables = var.env_variables
  }
}

resource "aws_lambda_permission" "sqs_invoke" {
  statement_id  = "AllowExecutionFromSQS"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda.function_name
  principal     = "sqs.amazonaws.com"
  source_arn    = aws_sqs_queue.service_queue.arn
}

resource "aws_lambda_event_source_mapping" "sqs_to_lambda" {
  event_source_arn = aws_sqs_queue.service_queue.arn
  function_name    = aws_lambda_function.lambda.arn
  enabled          = true
  batch_size       = 10
}
