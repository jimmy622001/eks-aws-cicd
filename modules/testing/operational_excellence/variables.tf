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
  description = "Email address for operational notifications"
  type        = string
}

variable "cloudtrail_name" {
  description = "Name of the CloudTrail to analyze"
  type        = string
  default     = ""
}

variable "suspicious_actions" {
  description = "List of CloudTrail actions to flag as suspicious"
  type        = list(string)
  default     = [
    "DeleteTrail", 
    "StopLogging", 
    "DeleteFlowLogs", 
    "DisableKeyRotation",
    "DeleteBucket",
    "DeleteDBCluster"
  ]
}

variable "jenkins_url" {
  description = "URL of the Jenkins instance"
  type        = string
  default     = ""
}

variable "jenkins_api_token" {
  description = "API token for Jenkins authentication"
  type        = string
  default     = ""
  sensitive   = true
}

variable "github_token" {
  description = "GitHub personal access token"
  type        = string
  default     = ""
  sensitive   = true
}

variable "github_repo" {
  description = "GitHub repository name in format owner/repo"
  type        = string
  default     = ""
}

variable "required_runbooks" {
  description = "List of required runbook documents"
  type        = list(string)
  default     = [
    "incident-response.md",
    "disaster-recovery.md",
    "deployment-procedure.md",
    "rollback-procedure.md",
    "scaling-procedure.md"
  ]
}

variable "required_alarms" {
  description = "Map of required CloudWatch alarms and their thresholds"
  type        = map(any)
  default     = {
    "high-cpu" = {
      metric_name = "CPUUtilization",
      namespace   = "AWS/EC2",
      threshold   = 80
    },
    "cluster-node-failure" = {
      metric_name = "cluster_failed_node_count",
      namespace   = "AWS/EKS",
      threshold   = 1
    },
    "5xx-errors" = {
      metric_name = "HTTPCode_ELB_5XX_Count",
      namespace   = "AWS/ApplicationELB",
      threshold   = 10
    }
  }
}

variable "required_dashboard_metrics" {
  description = "List of required metrics in CloudWatch dashboards"
  type        = list(string)
  default     = [
    "CPUUtilization",
    "MemoryUtilization",
    "HTTPCode_Target_4XX_Count",
    "HTTPCode_Target_5XX_Count"
  ]
}

variable "pagerduty_api_key" {
  description = "PagerDuty API key for incident response testing"
  type        = string
  default     = ""
  sensitive   = true
}

variable "pagerduty_service_id" {
  description = "PagerDuty service ID for incident response testing"
  type        = string
  default     = ""
}

variable "slack_webhook_url" {
  description = "Slack webhook URL for notifications"
  type        = string
  default     = ""
  sensitive   = true
}

variable "test_schedule_expression" {
  description = "CloudWatch Events schedule expression for automated testing"
  type        = string
  default     = "cron(0 2 * * ? *)" # Daily at 2 AM UTC
}