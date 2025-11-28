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

variable "domain_name" {
  description = "Domain name for the application"
  type        = string
}

variable "alb_domains" {
  description = "List of ALB domains to be used as origins"
  type        = list(string)
}

variable "acm_certificate_arn" {
  description = "ARN of the ACM certificate for the CDN"
  type        = string
}

variable "origin_domain_name" {
  description = "Domain name of the origin (like ALB DNS name)"
  type        = string
  default     = ""
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
}