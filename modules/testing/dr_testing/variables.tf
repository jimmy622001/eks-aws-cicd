variable "project_name" {
  description = "The name of the project"
  type        = string
}

variable "environment" {
  description = "The environment (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "enable_network_disruption_test" {
  description = "Whether to enable network disruption testing"
  type        = bool
  default     = true
}

variable "network_disruption_duration_minutes" {
  description = "Duration of network disruption test in minutes"
  type        = number
  default     = 5
}

variable "primary_region" {
  description = "The AWS region for the primary environment"
  type        = string
}

variable "dr_region" {
  description = "The AWS region for the DR environment"
  type        = string
}

variable "vpc_cidr_primary" {
  description = "CIDR for the primary VPC"
  type        = string
}

variable "vpc_cidr_dr" {
  description = "CIDR for the DR VPC"
  type        = string
}

variable "subnets_primary" {
  description = "List of subnet CIDRs for primary region"
  type        = list(string)
}

variable "subnets_dr" {
  description = "List of subnet CIDRs for DR region"
  type        = list(string)
}

variable "failover_components" {
  description = "List of components to include in failover tests"
  type        = list(string)
}

variable "test_timeout_minutes" {
  description = "Maximum duration for the DR test in minutes"
  type        = number
  default     = 30
}

variable "rto_threshold_minutes" {
  description = "Recovery Time Objective threshold in minutes"
  type        = number
  default     = 15
}

variable "rpo_threshold_minutes" {
  description = "Recovery Point Objective threshold in minutes"
  type        = number
  default     = 60
}

variable "target_rpo_seconds" {
  description = "Target Recovery Point Objective in seconds"
  type        = number
  default     = 300
}

variable "target_rto_minutes" {
  description = "Target Recovery Time Objective in minutes"
  type        = number
  default     = 15
}

variable "notification_email" {
  description = "Email address for test notifications"
  type        = string
}

variable "fis_experiments" {
  description = "List of FIS experiments to run"
  type        = list(string)
  default     = ["cpu-stress", "network-latency"]
}