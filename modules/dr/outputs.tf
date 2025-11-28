output "route53_failover_primary_record_id" {
  description = "ID of the Route53 failover primary record"
  value       = aws_route53_record.primary.id
}

output "health_check_id" {
  description = "ID of the Route53 health check"
  value       = aws_route53_health_check.primary.id
}

output "lambda_function_name" {
  description = "Name of the Lambda function that handles DR failover"
  value       = aws_lambda_function.failover_handler.function_name
}

output "cloudwatch_event_rule_name" {
  description = "Name of the CloudWatch event rule that triggers DR failover"
  value       = aws_cloudwatch_event_rule.failover_event.name
}