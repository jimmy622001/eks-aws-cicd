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

variable "notification_email" {
  description = "Email address for cost optimization notifications"
  type        = string
}

variable "monthly_budget_amount" {
  description = "Monthly budget amount in USD"
  type        = number
}

variable "cost_anomaly_threshold" {
  description = "Cost anomaly threshold percentage"
  type        = number
  default     = 10
}

variable "idle_cpu_threshold" {
  description = "CPU utilization threshold to identify idle EC2 resources (%)"
  type        = number
  default     = 10
}

variable "idle_ebs_threshold" {
  description = "IOPS threshold to identify idle EBS volumes"
  type        = number
  default     = 5
}

variable "ec2_lookback_days" {
  description = "Number of days to analyze EC2 usage for right-sizing"
  type        = number
  default     = 14
}

variable "rds_lookback_days" {
  description = "Number of days to analyze RDS usage for right-sizing"
  type        = number
  default     = 14
}

variable "ri_lookback_days" {
  description = "Number of days to analyze for RI coverage"
  type        = number
  default     = 30
}

variable "ri_target_coverage" {
  description = "Target percentage for RI coverage"
  type        = number
  default     = 80
}

variable "spot_min_savings_percent" {
  description = "Minimum savings percentage to recommend Spot instances"
  type        = number
  default     = 50
}

variable "required_resource_tags" {
  description = "List of required resource tags for compliance"
  type        = list(string)
  default     = ["Name", "Environment", "Project", "Owner", "CostCenter"]
}

variable "test_schedule_expression" {
  description = "CloudWatch Events schedule expression for automated testing"
  type        = string
  default     = "cron(0 1 * * ? *)" # Daily at 1 AM UTC
}