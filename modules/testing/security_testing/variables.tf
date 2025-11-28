variable "region" {
  description = "AWS region"
  type        = string
}

variable "environment" {
  description = "Environment (dev, test, prod)"
  type        = string
}

variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC to analyze"
  type        = string
}

variable "eks_cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "notification_email" {
  description = "Email address for notifications"
  type        = string
}

variable "enable_default_standards" {
  description = "Whether to enable default security standards"
  type        = bool
  default     = true
}

variable "enable_vpc_flow_log_analysis" {
  description = "Whether to enable VPC flow log analysis"
  type        = bool
  default     = true
}

variable "enable_db_security_assessment" {
  description = "Whether to enable database security assessment"
  type        = bool
  default     = true
}

variable "enable_simulated_pen_testing" {
  description = "Whether to enable simulated penetration testing"
  type        = bool
  default     = false
}

variable "pen_test_targets" {
  description = "List of targets for penetration testing"
  type        = list(string)
  default     = []
}