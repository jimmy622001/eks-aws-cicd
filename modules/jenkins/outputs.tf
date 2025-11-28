output "jenkins_url" {
  description = "URL of the Jenkins server"
  value       = "http://${kubernetes_service.jenkins_controller.status[0].load_balancer[0].ingress[0].hostname}"
}

output "jenkins_namespace" {
  description = "Kubernetes namespace where Jenkins is deployed"
  value       = kubernetes_namespace.jenkins.metadata[0].name
}

output "jenkins_service_account" {
  description = "ServiceAccount used by Jenkins"
  value       = kubernetes_service_account.jenkins.metadata[0].name
}

output "jenkins_role" {
  description = "IAM role created for Jenkins"
  value       = aws_iam_role.jenkins_role.name
}