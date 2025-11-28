# Security Testing module
resource "aws_lambda_function" "security_test" {
  function_name = "security_testing_function"
  handler       = "security_scanner.handler"
  runtime       = "nodejs14.x"
  role          = "arn:aws:iam::123456789012:role/lambda-role"
  
  filename = "lambda.zip"
  
  environment {
    variables = {
      ENV = "testing"
    }
  }
}