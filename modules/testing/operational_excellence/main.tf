/**
 * Operational Excellence Testing Module
 * This module implements comprehensive operational excellence testing capabilities
 * Covers AWS Well-Architected Framework Operational Excellence Pillar
 */

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 3.0.0"
    }
  }
}

# AWS provider configuration
provider "aws" {
  region = var.region
}

locals {
  tags = {
    Environment = var.environment
    Terraform   = "true"
    Module      = "operational_excellence_testing"
  }
}

# CloudWatch Dashboard Validation
resource "aws_lambda_function" "dashboard_validator" {
  function_name = "${var.project_name}-dashboard-validator"
  role          = aws_iam_role.lambda_role.arn
  handler       = "dashboard-validator.handler"
  runtime       = "nodejs16.x"
  timeout       = 300
  memory_size   = 256

  filename      = "${path.module}/lambda/dashboard_validator.zip"

  environment {
    variables = {
      ENVIRONMENT                = var.environment
      PROJECT_NAME               = var.project_name
      REGION                     = var.region
      REQUIRED_DASHBOARD_METRICS = jsonencode(var.required_dashboard_metrics)
      NOTIFICATION_SNS_ARN       = aws_sns_topic.operational_notifications.arn
    }
  }

  tags = local.tags
}

# CloudTrail Log Analysis
resource "aws_lambda_function" "cloudtrail_analyzer" {
  function_name = "${var.project_name}-cloudtrail-analyzer"
  role          = aws_iam_role.lambda_role.arn
  handler       = "cloudtrail-analyzer.handler"
  runtime       = "nodejs16.x"
  timeout       = 300
  memory_size   = 512

  filename      = "${path.module}/lambda/cloudtrail_analyzer.zip"

  environment {
    variables = {
      ENVIRONMENT          = var.environment
      PROJECT_NAME         = var.project_name
      REGION               = var.region
      TRAIL_NAME           = var.cloudtrail_name
      SUSPICIOUS_ACTIONS   = jsonencode(var.suspicious_actions)
      NOTIFICATION_SNS_ARN = aws_sns_topic.operational_notifications.arn
    }
  }

  tags = local.tags
}

# CI/CD Pipeline Validation
resource "aws_lambda_function" "pipeline_validator" {
  function_name = "${var.project_name}-pipeline-validator"
  role          = aws_iam_role.lambda_role.arn
  handler       = "pipeline-validator.handler"
  runtime       = "nodejs16.x"
  timeout       = 300
  memory_size   = 256

  filename      = "${path.module}/lambda/pipeline_validator.zip"

  environment {
    variables = {
      ENVIRONMENT          = var.environment
      PROJECT_NAME         = var.project_name
      REGION               = var.region
      JENKINS_URL          = var.jenkins_url
      JENKINS_API_TOKEN    = var.jenkins_api_token
      NOTIFICATION_SNS_ARN = aws_sns_topic.operational_notifications.arn
    }
  }

  tags = local.tags
}

# Documentation Validator (checks for README and other essential docs)
resource "aws_lambda_function" "documentation_validator" {
  function_name = "${var.project_name}-docs-validator"
  role          = aws_iam_role.lambda_role.arn
  handler       = "docs-validator.handler"
  runtime       = "nodejs16.x"
  timeout       = 300
  memory_size   = 256

  filename      = "${path.module}/lambda/docs_validator.zip"

  environment {
    variables = {
      ENVIRONMENT          = var.environment
      PROJECT_NAME         = var.project_name
      REGION               = var.region
      GITHUB_TOKEN         = var.github_token
      GITHUB_REPO          = var.github_repo
      NOTIFICATION_SNS_ARN = aws_sns_topic.operational_notifications.arn
    }
  }

  tags = local.tags
}

# Runbook Validator
resource "aws_lambda_function" "runbook_validator" {
  function_name = "${var.project_name}-runbook-validator"
  role          = aws_iam_role.lambda_role.arn
  handler       = "runbook-validator.handler"
  runtime       = "nodejs16.x"
  timeout       = 300
  memory_size   = 256

  filename      = "${path.module}/lambda/runbook_validator.zip"

  environment {
    variables = {
      ENVIRONMENT          = var.environment
      PROJECT_NAME         = var.project_name
      REGION               = var.region
      GITHUB_TOKEN         = var.github_token
      GITHUB_REPO          = var.github_repo
      REQUIRED_RUNBOOKS    = jsonencode(var.required_runbooks)
      NOTIFICATION_SNS_ARN = aws_sns_topic.operational_notifications.arn
    }
  }

  tags = local.tags
}

# Alarm Configuration Validator
resource "aws_lambda_function" "alarm_validator" {
  function_name = "${var.project_name}-alarm-validator"
  role          = aws_iam_role.lambda_role.arn
  handler       = "alarm-validator.handler"
  runtime       = "nodejs16.x"
  timeout       = 300
  memory_size   = 256

  filename      = "${path.module}/lambda/alarm_validator.zip"

  environment {
    variables = {
      ENVIRONMENT          = var.environment
      PROJECT_NAME         = var.project_name
      REGION               = var.region
      REQUIRED_ALARMS      = jsonencode(var.required_alarms)
      NOTIFICATION_SNS_ARN = aws_sns_topic.operational_notifications.arn
    }
  }

  tags = local.tags
}

# Incident Response Test
resource "aws_lambda_function" "incident_response_test" {
  function_name = "${var.project_name}-incident-response-test"
  role          = aws_iam_role.lambda_role.arn
  handler       = "incident-response.handler"
  runtime       = "nodejs16.x"
  timeout       = 300
  memory_size   = 256

  filename      = "${path.module}/lambda/incident_response.zip"

  environment {
    variables = {
      ENVIRONMENT          = var.environment
      PROJECT_NAME         = var.project_name
      REGION               = var.region
      SNS_TOPIC_ARN        = aws_sns_topic.operational_notifications.arn
      PAGERDUTY_API_KEY    = var.pagerduty_api_key
      PAGERDUTY_SERVICE_ID = var.pagerduty_service_id
      SLACK_WEBHOOK_URL    = var.slack_webhook_url
    }
  }

  tags = local.tags
}

# SNS Topic for Notifications
resource "aws_sns_topic" "operational_notifications" {
  name = "${var.project_name}-${var.environment}-operational-excellence"
  
  tags = local.tags
}

resource "aws_sns_topic_subscription" "email_subscription" {
  topic_arn = aws_sns_topic.operational_notifications.arn
  protocol  = "email"
  endpoint  = var.notification_email
}

# CloudWatch Dashboard for Operational Excellence Metrics
resource "aws_cloudwatch_dashboard" "ops_dashboard" {
  dashboard_name = "${var.project_name}-${var.environment}-operational-excellence"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "text"
        x      = 0
        y      = 0
        width  = 24
        height = 2
        properties = {
          markdown = "# Operational Excellence Dashboard for ${var.project_name} (${var.environment})\nLast Updated: $${Date.now()}"
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 2
        width  = 12
        height = 6
        properties = {
          metrics = [
            [ "AWS/CloudWatch", "AlarmStateChanged", "State", "ALARM" ],
            [ "AWS/CloudWatch", "AlarmStateChanged", "State", "OK" ]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.region
          title   = "CloudWatch Alarm State Changes"
          period  = 3600
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 2
        width  = 12
        height = 6
        properties = {
          metrics = [
            [ { "expression": "SEARCH('{AWS/Lambda,FunctionName} MetricName=\"Errors\"', 'Sum', 3600)", "id": "e1", "color": "#d62728" } ],
            [ { "expression": "SEARCH('{AWS/Lambda,FunctionName} MetricName=\"Invocations\"', 'Sum', 3600)", "id": "e2", "color": "#2ca02c" } ]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.region
          title   = "Lambda Errors vs Invocations"
          period  = 3600
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 8
        width  = 12
        height = 6
        properties = {
          metrics = [
            [ "AWS/Events", "TriggeredRules", "RuleName", "EVENT_RULE_NAME" ],
            [ "AWS/Events", "FailedInvocations", "RuleName", "EVENT_RULE_NAME" ]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.region
          title   = "CloudWatch Events Triggered vs Failed"
          period  = 3600
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 8
        width  = 12
        height = 6
        properties = {
          metrics = [
            [ "AWS/Lambda", "Invocations", "FunctionName", "${var.project_name}-cloudtrail-analyzer" ],
            [ "AWS/Lambda", "Invocations", "FunctionName", "${var.project_name}-pipeline-validator" ],
            [ "AWS/Lambda", "Invocations", "FunctionName", "${var.project_name}-docs-validator" ],
            [ "AWS/Lambda", "Invocations", "FunctionName", "${var.project_name}-runbook-validator" ]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.region
          title   = "Operational Excellence Test Executions"
          period  = 86400
        }
      }
    ]
  })
}

# IAM Role for Lambda functions
resource "aws_iam_role" "lambda_role" {
  name = "lambda-operational-excellence-role-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = local.tags
}

# IAM Policy for Lambda functions
resource "aws_iam_policy" "lambda_policy" {
  name        = "lambda-operational-excellence-policy-${var.environment}"
  description = "Policy for operational excellence Lambda functions"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Effect   = "Allow",
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Action = [
          "cloudwatch:DescribeAlarms",
          "cloudwatch:GetDashboard",
          "cloudwatch:ListDashboards",
          "cloudtrail:LookupEvents",
          "cloudtrail:DescribeTrails",
          "sns:Publish",
          "codepipeline:ListPipelines",
          "codepipeline:GetPipelineState",
          "codebuild:ListProjects",
          "codebuild:BatchGetBuilds",
          "s3:ListBucket",
          "s3:GetObject",
          "events:ListRules",
          "events:ListTargetsByRule",
          "ssm:ListDocuments",
          "ssm:GetDocument",
          "lambda:ListFunctions",
          "lambda:GetFunction",
          "cloudwatch:GetMetricData"
        ],
        Effect   = "Allow",
        Resource = "*"
      }
    ]
  })
}

# Attach the policy to the role
resource "aws_iam_role_policy_attachment" "lambda_policy_attachment" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_policy.arn
}

# CloudWatch Event to trigger operational excellence tests on schedule
resource "aws_cloudwatch_event_rule" "ops_test_schedule" {
  name                = "${var.project_name}-${var.environment}-ops-test-schedule"
  description         = "Trigger operational excellence tests on schedule"
  schedule_expression = var.test_schedule_expression

  tags = local.tags
}

# Set up event targets for each Lambda function
resource "aws_cloudwatch_event_target" "cloudtrail_analyzer_target" {
  rule      = aws_cloudwatch_event_rule.ops_test_schedule.name
  target_id = "CloudtrailAnalyzer"
  arn       = aws_lambda_function.cloudtrail_analyzer.arn
}

resource "aws_lambda_permission" "allow_cloudwatch_to_call_cloudtrail_analyzer" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.cloudtrail_analyzer.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.ops_test_schedule.arn
}

resource "aws_cloudwatch_event_target" "pipeline_validator_target" {
  rule      = aws_cloudwatch_event_rule.ops_test_schedule.name
  target_id = "PipelineValidator"
  arn       = aws_lambda_function.pipeline_validator.arn
}

resource "aws_lambda_permission" "allow_cloudwatch_to_call_pipeline_validator" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.pipeline_validator.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.ops_test_schedule.arn
}

resource "aws_cloudwatch_event_target" "docs_validator_target" {
  rule      = aws_cloudwatch_event_rule.ops_test_schedule.name
  target_id = "DocsValidator"
  arn       = aws_lambda_function.documentation_validator.arn
}

resource "aws_lambda_permission" "allow_cloudwatch_to_call_docs_validator" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.documentation_validator.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.ops_test_schedule.arn
}