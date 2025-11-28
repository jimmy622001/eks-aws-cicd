output "vpc_id" {
  description = "The ID of the VPC"
  value       = module.vpc.vpc_id
}

output "eks_cluster_name" {
  description = "The name of the EKS cluster"
  value       = module.eks.cluster_name
}

output "eks_cluster_endpoint" {
  description = "The endpoint for the EKS cluster"
  value       = module.eks.cluster_endpoint
}

output "prometheus_url" {
  description = "URL for Prometheus"
  value       = module.monitoring.prometheus_url
}

output "grafana_url" {
  description = "URL for Grafana"
  value       = module.monitoring.grafana_url
}

output "rancher_url" {
  description = "URL for Rancher"
  value       = module.monitoring.rancher_url
}

output "route53_failover_primary_record_id" {
  description = "ID of the Route53 failover primary record"
  value       = module.dr.route53_failover_primary_record_id
}

output "lambda_function_name" {
  description = "Name of the Lambda function that handles DR failover"
  value       = module.dr.lambda_function_name
}

output "kubectl_config_command" {
  description = "Command to configure kubectl"
  value       = module.eks.kubectl_config
}