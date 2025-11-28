output "fis_experiment_template_id" {
  description = "ID of the created FIS experiment template"
  value       = aws_fis_experiment_template.dr_test.id
}

output "rpo_validator_lambda_arn" {
  description = "ARN of the RPO validation Lambda function"
  value       = aws_lambda_function.rpo_validator.arn
}

output "rto_validator_lambda_arn" {
  description = "ARN of the RTO validation Lambda function"
  value       = aws_lambda_function.rto_validator.arn
}

output "fis_role_arn" {
  description = "ARN of the IAM role for FIS"
  value       = aws_iam_role.fis_role.arn
}