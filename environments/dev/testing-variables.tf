# Variables for testing modules

variable "notification_emails" {
  description = "Map of notification email addresses for different purposes"
  type        = map(string)
  default = {
    devops  = "devops@example.com"
    finance = "finance@example.com"
    security = "security@example.com"
  }
}

variable "github_repo" {
  description = "GitHub repository name in format owner/repo"
  type        = string
  default     = "example-org/eks-aws-cicd"
}

variable "monthly_budget_amount" {
  description = "Monthly budget amount in USD for cost optimization testing"
  type        = number
  default     = 5000
}

variable "dr_region" {
  description = "Secondary region for DR testing"
  type        = string
  default     = "us-west-2"
}

variable "dr_vpc_cidr" {
  description = "CIDR for the DR VPC"
  type        = string
  default     = "10.1.0.0/16"
}

variable "dr_public_subnet_cidr" {
  description = "CIDR block for DR public subnet"
  type        = string
  default     = "10.1.1.0/24"
}

variable "dr_private_subnet_cidr" {
  description = "CIDR block for DR private subnet"
  type        = string
  default     = "10.1.2.0/24"
}

variable "dr_db_subnet_cidr" {
  description = "CIDR block for DR database subnet"
  type        = string
  default     = "10.1.3.0/24"
}

variable "dr_availability_zone" {
  description = "Availability zone for DR subnets"
  type        = string
  default     = "us-west-2a"
}

variable "health_check_path" {
  description = "Health check path for DR testing"
  type        = string
  default     = "/healthz"
}

variable "health_check_interval" {
  description = "Health check interval in seconds"
  type        = number
  default     = 30
}

variable "failover_threshold" {
  description = "Failover threshold in seconds"
  type        = number
  default     = 60
}