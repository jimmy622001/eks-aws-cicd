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

variable "jenkins_namespace" {
  description = "Kubernetes namespace for Jenkins"
  type        = string
}

variable "jenkins_controller_resources" {
  description = "Resource limits and requests for Jenkins controller"
  type = object({
    limits = object({
      cpu    = string
      memory = string
    })
    requests = object({
      cpu    = string
      memory = string
    })
  })
}

variable "jenkins_agent_resources" {
  description = "Resource limits and requests for Jenkins agents"
  type = object({
    limits = object({
      cpu    = string
      memory = string
    })
    requests = object({
      cpu    = string
      memory = string
    })
  })
}

variable "jenkins_controller_storage_size" {
  description = "Size of persistent volume for Jenkins controller"
  type        = string
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
}