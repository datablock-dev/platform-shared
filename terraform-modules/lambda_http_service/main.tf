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
    Statement : concat(var.additional_iam_statements)
  })
}

resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_lambda_function" "lambda" {
  function_name    = "${terraform.workspace}-minfaktura-http-${var.service_name}"
  role             = aws_iam_role.lambda_role.arn
  runtime          = var.lambda_runtime
  handler          = var.lambda_handler
  filename         = "${path.module}/../../../../backend/services/${var.service_name}/dist.zip"
  source_code_hash = filebase64sha256("${path.module}/../../../../backend/services/${var.service_name}/dist.zip")
  timeout          = var.lambda_timeout

  environment {
    variables = var.env_variables
  }
}

resource "aws_apigatewayv2_api" "http_api" {
  name          = "${terraform.workspace}-${var.service_name}-http-api"
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_integration" "lambda_integration" {
  api_id                 = aws_apigatewayv2_api.http_api.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.this.invoke_arn
  integration_method     = "POST"
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "default_route" {
  api_id    = aws_apigatewayv2_api.http_api.id
  route_key = "POST"  # e.g. "POST /create-user"
  target    = "integrations/${aws_apigatewayv2_integration.lambda_integration.id}"
}

resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.http_api.id
  name        = "$default"
  auto_deploy = true
}

resource "aws_lambda_permission" "allow_api_invoke" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.this.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.http_api.execution_arn}/*/*"
}