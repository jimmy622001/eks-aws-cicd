variable "region" {
  description = "AWS region"
  type        = string
}

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "gateway_namespace" {
  description = "Kubernetes namespace for Gateway API resources"
  type        = string
  default     = "gateway-system"
}

variable "eks_oidc_provider_arn" {
  description = "ARN of the OIDC provider associated with the EKS cluster"
  type        = string
}

variable "eks_oidc_provider_url" {
  description = "URL of the OIDC provider associated with the EKS cluster"
  type        = string
}