output "lambda_arn" {
  description = "ARN of the validation Lambda function"
  value       = aws_lambda_function.validation.arn
}