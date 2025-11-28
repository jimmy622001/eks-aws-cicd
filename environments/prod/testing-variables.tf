# Variables for testing modules in production

variable "notification_emails" {
  description = "Map of notification email addresses for different purposes"
  type        = map(string)
  default = {
    devops    = "prod-devops@example.com"
    finance   = "prod-finance@example.com"
    security  = "prod-security@example.com"
    operations = "prod-operations@example.com"
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
  default     = 15000
}

variable "health_check_path" {
  description = "Health check path for DR testing"
  type        = string
  default     = "/healthz"
}

variable "health_check_interval" {
  description = "Health check interval in seconds"
  type        = number
  default     = 10  # More frequent checks in production
}

variable "failover_threshold" {
  description = "Failover threshold in seconds"
  type        = number
  default     = 30  # Lower threshold for production
}