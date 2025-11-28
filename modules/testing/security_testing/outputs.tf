output "security_test_lambda_arn" {
  description = "ARN of the security test Lambda function"
  value       = aws_lambda_function.security_test.arn
}