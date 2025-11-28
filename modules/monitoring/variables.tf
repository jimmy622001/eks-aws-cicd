variable "project" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, prod, dr)"
  type        = string
}

variable "region" {
  description = "AWS region"
  type        = string
}

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "eks_cluster_endpoint" {
  description = "Endpoint for the EKS cluster"
  type        = string
}

variable "eks_oidc_provider_arn" {
  description = "ARN of the OIDC provider associated with EKS cluster"
  type        = string
}

variable "prometheus_namespace" {
  description = "Kubernetes namespace for Prometheus and Grafana"
  type        = string
}

variable "rancher_namespace" {
  description = "Kubernetes namespace for Rancher"
  type        = string
}

variable "rancher_hostname" {
  description = "Hostname for Rancher"
  type        = string
}

variable "prometheus_storage_size" {
  description = "Size of persistent volume for Prometheus"
  type        = string
}

variable "grafana_storage_size" {
  description = "Size of persistent volume for Grafana"
  type        = string
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
}