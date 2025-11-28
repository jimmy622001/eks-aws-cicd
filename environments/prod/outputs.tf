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

output "cloudfront_url" {
  description = "URL for the CloudFront distribution"
  value       = module.cdn.cloudfront_url
}

output "kubectl_config_command" {
  description = "Command to configure kubectl"
  value       = module.eks.kubectl_config
}