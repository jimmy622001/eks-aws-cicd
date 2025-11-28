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

variable "eks_cluster_name" {
  description = "Name of the EKS cluster to test"
  type        = string
}

variable "target_node_count" {
  description = "Target number of nodes for scaling tests"
  type        = number
  default     = 3
}

variable "scaling_test_duration_minutes" {
  description = "Duration of the scaling test in minutes"
  type        = number
  default     = 15
}

variable "load_test_endpoint" {
  description = "Endpoint URL to test"
  type        = string
}

variable "load_test_duration_minutes" {
  description = "Duration of load test in minutes"
  type        = number
  default     = 10
}

variable "load_test_users_per_second" {
  description = "Number of virtual users per second for load testing"
  type        = number
  default     = 10
}

variable "load_test_rps_target" {
  description = "Target requests per second for load test"
  type        = number
  default     = 100
}

variable "cpu_utilization_threshold" {
  description = "CPU utilization threshold percentage for alerting"
  type        = number
  default     = 80
}

variable "memory_utilization_threshold" {
  description = "Memory utilization threshold percentage for alerting"
  type        = number
  default     = 80
}

variable "alb_name" {
  description = "Name of the Application Load Balancer to monitor"
  type        = string
  default     = ""
}

variable "api_gateway_name" {
  description = "Name of the API Gateway to monitor"
  type        = string
  default     = ""
}

variable "test_schedule_expression" {
  description = "CloudWatch Events schedule expression for automated testing"
  type        = string
  default     = "rate(7 days)"
}