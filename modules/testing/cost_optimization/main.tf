/**
 * Cost Optimization Testing Module
 * This module implements comprehensive cost optimization testing capabilities
 * Covers AWS Well-Architected Framework Cost Optimization Pillar
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
    Module      = "cost_optimization_testing"
  }
}

# Enable AWS Cost Explorer
resource "aws_ce_anomaly_monitor" "cost_anomaly_monitor" {
  name              = "${var.project_name}-${var.environment}-cost-anomaly-monitor"
  monitor_type      = "DIMENSIONAL"
  
  monitor_dimension = "SERVICE"

  tags = local.tags
}

resource "aws_ce_anomaly_subscription" "cost_anomaly_subscription" {
  name             = "${var.project_name}-${var.environment}-cost-anomaly-subscription"
  frequency        = "DAILY"
  monitor_arn_list = [aws_ce_anomaly_monitor.cost_anomaly_monitor.arn]

  subscriber {
    type      = "EMAIL"
    address   = var.notification_email
  }
}

# AWS Budgets
resource "aws_budgets_budget" "monthly_budget" {
  name              = "${var.project_name}-${var.environment}-monthly-budget"
  budget_type       = "COST"
  time_unit         = "MONTHLY"
  time_period_start = "2023-01-01_00:00"
  
  limit_amount      = var.monthly_budget_amount
  limit_unit        = "USD"

  notification {
    comparison_operator = "GREATER_THAN"
    threshold           = 80
    threshold_type      = "PERCENTAGE"
    notification_type   = "ACTUAL"
    
    subscriber_email_addresses = [var.notification_email]
  }

  notification {
    comparison_operator = "GREATER_THAN"
    threshold           = 100
    threshold_type      = "PERCENTAGE"
    notification_type   = "FORECASTED"
    
    subscriber_email_addresses = [var.notification_email]
  }

  cost_types {
    include_credit = false
    include_discount = true
    include_other_subscription = true
    include_recurring = true
    include_refund = false
    include_subscription = true
    include_support = true
    include_tax = true
    include_upfront = true
    use_blended = false
  }
}

# Idle Resource Detection Lambda
resource "aws_lambda_function" "idle_resource_detector" {
  function_name = "${var.project_name}-idle-resource-detector"
  role          = aws_iam_role.lambda_role.arn
  handler       = "idle-detector.handler"
  runtime       = "nodejs16.x"
  timeout       = 300
  memory_size   = 256

  filename      = "${path.module}/lambda/idle_detector.zip"

  environment {
    variables = {
      ENVIRONMENT           = var.environment
      PROJECT_NAME          = var.project_name
      REGION               = var.region
      CPU_THRESHOLD        = var.idle_cpu_threshold
      EBS_THRESHOLD        = var.idle_ebs_threshold
      NOTIFICATION_SNS_ARN = aws_sns_topic.cost_optimization_notifications.arn
    }
  }

  tags = local.tags
}

# Right-sizing Recommendation Lambda
resource "aws_lambda_function" "right_sizing_recommender" {
  function_name = "${var.project_name}-right-sizing-recommender"
  role          = aws_iam_role.lambda_role.arn
  handler       = "right-sizing.handler"
  runtime       = "nodejs16.x"
  timeout       = 300
  memory_size   = 256

  filename      = "${path.module}/lambda/right_sizing.zip"

  environment {
    variables = {
      ENVIRONMENT           = var.environment
      PROJECT_NAME          = var.project_name
      REGION               = var.region
      EC2_LOOKBACK_DAYS    = var.ec2_lookback_days
      RDS_LOOKBACK_DAYS    = var.rds_lookback_days
      NOTIFICATION_SNS_ARN = aws_sns_topic.cost_optimization_notifications.arn
    }
  }

  tags = local.tags
}

# Reserved Instance Coverage Analyzer
resource "aws_lambda_function" "ri_coverage_analyzer" {
  function_name = "${var.project_name}-ri-coverage-analyzer"
  role          = aws_iam_role.lambda_role.arn
  handler       = "ri-coverage.handler"
  runtime       = "nodejs16.x"
  timeout       = 300
  memory_size   = 256

  filename      = "${path.module}/lambda/ri_coverage.zip"

  environment {
    variables = {
      ENVIRONMENT           = var.environment
      PROJECT_NAME          = var.project_name
      REGION               = var.region
      LOOKBACK_DAYS        = var.ri_lookback_days
      TARGET_COVERAGE      = var.ri_target_coverage
      NOTIFICATION_SNS_ARN = aws_sns_topic.cost_optimization_notifications.arn
    }
  }

  tags = local.tags
}

# Spot Instance Opportunity Analyzer
resource "aws_lambda_function" "spot_opportunity_analyzer" {
  function_name = "${var.project_name}-spot-opportunity-analyzer"
  role          = aws_iam_role.lambda_role.arn
  handler       = "spot-opportunity.handler"
  runtime       = "nodejs16.x"
  timeout       = 300
  memory_size   = 256

  filename      = "${path.module}/lambda/spot_opportunity.zip"

  environment {
    variables = {
      ENVIRONMENT           = var.environment
      PROJECT_NAME          = var.project_name
      REGION               = var.region
      MIN_SAVINGS_PERCENT  = var.spot_min_savings_percent
      NOTIFICATION_SNS_ARN = aws_sns_topic.cost_optimization_notifications.arn
    }
  }

  tags = local.tags
}

# Resource Tagging Compliance Lambda
resource "aws_lambda_function" "tagging_compliance_checker" {
  function_name = "${var.project_name}-tagging-compliance-checker"
  role          = aws_iam_role.lambda_role.arn
  handler       = "tagging-compliance.handler"
  runtime       = "nodejs16.x"
  timeout       = 300
  memory_size   = 256

  filename      = "${path.module}/lambda/tagging_compliance.zip"

  environment {
    variables = {
      ENVIRONMENT           = var.environment
      PROJECT_NAME          = var.project_name
      REGION               = var.region
      REQUIRED_TAGS        = jsonencode(var.required_resource_tags)
      NOTIFICATION_SNS_ARN = aws_sns_topic.cost_optimization_notifications.arn
    }
  }

  tags = local.tags
}

# SNS Topic for Notifications
resource "aws_sns_topic" "cost_optimization_notifications" {
  name = "${var.project_name}-${var.environment}-cost-optimization"
  
  tags = local.tags
}

resource "aws_sns_topic_subscription" "email_subscription" {
  topic_arn = aws_sns_topic.cost_optimization_notifications.arn
  protocol  = "email"
  endpoint  = var.notification_email
}

# CloudWatch Dashboard for Cost Metrics
resource "aws_cloudwatch_dashboard" "cost_dashboard" {
  dashboard_name = "${var.project_name}-${var.environment}-cost-optimization"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "text"
        x      = 0
        y      = 0
        width  = 24
        height = 2
        properties = {
          markdown = "# Cost Optimization Dashboard for ${var.project_name} (${var.environment})\nLast Updated: $${Date.now()}"
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
            [ "AWS/Billing", "EstimatedCharges", "ServiceName", "AmazonEKS" ],
            [ "...", "AmazonEC2" ],
            [ "...", "AmazonS3" ],
            [ "...", "AmazonRDS" ],
            [ "...", "AmazonRoute53" ]
          ]
          view    = "timeSeries"
          stacked = false
          region  = "us-east-1"  # Billing metrics are in us-east-1
          title   = "Estimated Charges by Service"
          period  = 86400
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
            [ "AWS/EC2", "CPUUtilization", "InstanceId", "*", { "stat": "Average" } ]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.region
          title   = "EC2 CPU Utilization (Potential Right-sizing)"
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
            [ "AWS/EBS", "VolumeReadOps", "VolumeId", "*", { "stat": "Average" } ],
            [ "AWS/EBS", "VolumeWriteOps", "VolumeId", "*", { "stat": "Average" } ]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.region
          title   = "EBS Volume Activity (Potential Idle Volumes)"
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
            [ "AWS/Lambda", "Invocations", "FunctionName", "${var.project_name}-idle-resource-detector" ],
            [ "AWS/Lambda", "Invocations", "FunctionName", "${var.project_name}-right-sizing-recommender" ],
            [ "AWS/Lambda", "Invocations", "FunctionName", "${var.project_name}-ri-coverage-analyzer" ],
            [ "AWS/Lambda", "Invocations", "FunctionName", "${var.project_name}-spot-opportunity-analyzer" ]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.region
          title   = "Cost Optimization Test Executions"
          period  = 86400
        }
      }
    ]
  })
}

# IAM Role for Lambda functions
resource "aws_iam_role" "lambda_role" {
  name = "lambda-cost-optimization-role-${var.environment}"

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
  name        = "lambda-cost-optimization-policy-${var.environment}"
  description = "Policy for cost optimization Lambda functions"

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
          "ce:GetCostAndUsage",
          "ce:GetReservationUtilization",
          "ce:GetReservationCoverage",
          "ce:GetDimensionValues",
          "ce:GetSavingsPlansCoverage",
          "ec2:DescribeInstances",
          "ec2:DescribeVolumes",
          "ec2:DescribeSnapshots",
          "ec2:DescribeAddresses",
          "ec2:DescribeSpotPriceHistory",
          "ec2:DescribeReservedInstances",
          "rds:DescribeDBInstances",
          "rds:DescribeDBClusters",
          "elasticache:DescribeCacheClusters",
          "elasticloadbalancing:DescribeLoadBalancers",
          "elasticloadbalancing:DescribeTargetGroups",
          "sns:Publish",
          "cloudwatch:GetMetricData",
          "cloudwatch:GetMetricStatistics",
          "tag:GetResources",
          "tag:TagResources",
          "tag:GetTagKeys"
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

# CloudWatch Event to trigger cost optimization tests on schedule
resource "aws_cloudwatch_event_rule" "cost_test_schedule" {
  name                = "${var.project_name}-${var.environment}-cost-test-schedule"
  description         = "Trigger cost optimization tests on schedule"
  schedule_expression = var.test_schedule_expression

  tags = local.tags
}

resource "aws_cloudwatch_event_target" "idle_resource_target" {
  rule      = aws_cloudwatch_event_rule.cost_test_schedule.name
  target_id = "IdleResourceDetector"
  arn       = aws_lambda_function.idle_resource_detector.arn
}

resource "aws_lambda_permission" "allow_cloudwatch_to_call_idle_detector" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.idle_resource_detector.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.cost_test_schedule.arn
}

resource "aws_cloudwatch_event_target" "right_sizing_target" {
  rule      = aws_cloudwatch_event_rule.cost_test_schedule.name
  target_id = "RightSizingRecommender"
  arn       = aws_lambda_function.right_sizing_recommender.arn
}

resource "aws_lambda_permission" "allow_cloudwatch_to_call_right_sizing" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.right_sizing_recommender.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.cost_test_schedule.arn
}