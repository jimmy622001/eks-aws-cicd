# DR Testing module
resource "aws_lambda_function" "dr_test" {
  function_name = "dr_testing_function"
  handler       = "index.handler"
  runtime       = "nodejs14.x"
  role          = "arn:aws:iam::123456789012:role/lambda-role"
  
  filename = "lambda.zip"
  
  environment {
    variables = {
      ENV = "testing"
    }
  }
}