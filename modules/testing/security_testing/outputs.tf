output "security_hub_arn" {
  description = "ARN of the Security Hub"
  value       = aws_securityhub_account.security_hub.id
}

output "guardduty_detector_id" {
  description = "ID of the GuardDuty detector"
  value       = aws_guardduty_detector.main.id
}

output "config_recorder_id" {
  description = "ID of the AWS Config recorder"
  value       = aws_config_configuration_recorder.config.id
}

output "security_scanner_lambda_arn" {
  description = "ARN of the security scanner Lambda function"
  value       = aws_lambda_function.security_scanner.arn
}