output "prometheus_url" {
  description = "URL of the Prometheus server"
  value       = "http://${kubernetes_service.prometheus.status[0].load_balancer[0].ingress[0].hostname}"
}

output "grafana_url" {
  description = "URL of the Grafana dashboard"
  value       = "http://${kubernetes_service.grafana.status[0].load_balancer[0].ingress[0].hostname}"
}

output "rancher_url" {
  description = "URL of the Rancher management server"
  value       = "https://${var.rancher_hostname}"
}

output "monitoring_namespace" {
  description = "Kubernetes namespace for Prometheus and Grafana"
  value       = kubernetes_namespace.monitoring.metadata[0].name
}

output "rancher_namespace" {
  description = "Kubernetes namespace for Rancher"
  value       = kubernetes_namespace.rancher.metadata[0].name
}