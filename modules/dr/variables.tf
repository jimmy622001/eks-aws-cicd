variable "project" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment name (dr)"
  type        = string
}

variable "region" {
  description = "AWS region for DR"
  type        = string
}

variable "primary_region" {
  description = "AWS region of the primary environment"
  type        = string
}

variable "domain_name" {
  description = "Domain name for the application"
  type        = string
}

variable "primary_endpoint" {
  description = "Endpoint of the primary environment"
  type        = string
}

variable "dr_endpoint" {
  description = "Endpoint of the DR environment"
  type        = string
}

variable "health_check_path" {
  description = "Path for Route53 health check"
  type        = string
}

variable "health_check_interval" {
  description = "Interval for health checks in seconds"
  type        = number
}

variable "failover_threshold" {
  description = "Number of consecutive failed health checks to trigger failover"
  type        = number
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
}

variable "cluster_name" {
  description = "Name of the DR EKS cluster"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs"
  type        = list(string)
}