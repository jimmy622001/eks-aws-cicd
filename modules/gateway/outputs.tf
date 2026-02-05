output "gateway_controller_role_arn" {
  description = "ARN of the IAM role created for the Gateway controller"
  value       = aws_iam_role.gateway_controller_role.arn
}

output "gateway_class_name" {
  description = "Name of the created GatewayClass"
  value       = kubernetes_manifest.gateway_class.manifest.metadata.name
}

output "default_gateway_name" {
  description = "Name of the default Gateway"
  value       = kubernetes_manifest.default_gateway.manifest.metadata.name
}

output "gateway_namespace" {
  description = "Kubernetes namespace where Gateway controller is deployed"
  value       = kubernetes_namespace.gateway_system.metadata[0].name
}