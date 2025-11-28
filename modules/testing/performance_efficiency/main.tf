/**
 * Performance Efficiency Testing Module
 * This module implements comprehensive performance testing capabilities
 * Covers AWS Well-Architected Framework Performance Efficiency Pillar
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
    Module      = "performance_efficiency_testing"
  }
}

# EKS Cluster Autoscaling Test
resource "aws_lambda_function" "eks_scaling_test" {
  function_name = "${var.project_name}-eks-scaling-test"
  role          = aws_iam_role.lambda_role.arn
  handler       = "eks-scaling-test.handler"
  runtime       = "nodejs16.x"
  timeout       = 600
  memory_size   = 256

  filename      = "${path.module}/lambda/eks_scaling_test.zip"

  environment {
    variables = {
      ENVIRONMENT       = var.environment
      PROJECT_NAME      = var.project_name
      REGION           = var.region
      EKS_CLUSTER_NAME = var.eks_cluster_name
      TARGET_NODES     = var.target_node_count
      TEST_DURATION    = var.scaling_test_duration_minutes
    }
  }

  tags = local.tags
}

# Load Testing Resources
resource "aws_lambda_function" "load_test_controller" {
  function_name = "${var.project_name}-load-test-controller"
  role          = aws_iam_role.lambda_role.arn
  handler       = "load-test.handler"
  runtime       = "nodejs16.x"
  timeout       = 900
  memory_size   = 1024

  filename      = "${path.module}/lambda/load_test.zip"

  environment {
    variables = {
      ENVIRONMENT       = var.environment
      PROJECT_NAME      = var.project_name
      REGION           = var.region
      TARGET_ENDPOINT  = var.load_test_endpoint
      TEST_DURATION    = var.load_test_duration_minutes
      USERS_PER_SECOND = var.load_test_users_per_second
      RPS_TARGET       = var.load_test_rps_target
    }
  }

  tags = local.tags
}

# Resource Utilization Analysis
resource "aws_lambda_function" "resource_utilization_analyzer" {
  function_name = "${var.project_name}-resource-analyzer"
  role          = aws_iam_role.lambda_role.arn
  handler       = "resource-analyzer.handler"
  runtime       = "nodejs16.x"
  timeout       = 300
  memory_size   = 256

  filename      = "${path.module}/lambda/resource_analyzer.zip"

  environment {
    variables = {
      ENVIRONMENT       = var.environment
      PROJECT_NAME      = var.project_name
      REGION           = var.region
      EKS_CLUSTER_NAME = var.eks_cluster_name
      CPU_THRESHOLD    = var.cpu_utilization_threshold
      MEMORY_THRESHOLD = var.memory_utilization_threshold
    }
  }

  tags = local.tags
}

# CloudWatch Dashboard for Performance Metrics
resource "aws_cloudwatch_dashboard" "performance_dashboard" {
  dashboard_name = "${var.project_name}-${var.environment}-performance"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/EKS", "cluster_failed_node_count", "ClusterName", var.eks_cluster_name],
            ["AWS/EKS", "node_cpu_utilization", "ClusterName", var.eks_cluster_name]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.region
          title   = "EKS Cluster Node CPU Utilization"
          period  = 300
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 0
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/EKS", "node_memory_utilization", "ClusterName", var.eks_cluster_name]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.region
          title   = "EKS Cluster Memory Utilization"
          period  = 300
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/ApplicationELB", "RequestCount", "LoadBalancer", var.alb_name],
            ["AWS/ApplicationELB", "TargetResponseTime", "LoadBalancer", var.alb_name]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.region
          title   = "Application Load"
          period  = 60
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 6
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/ApiGateway", "4XXError", "ApiName", var.api_gateway_name],
            ["AWS/ApiGateway", "5XXError", "ApiName", var.api_gateway_name],
            ["AWS/ApiGateway", "Count", "ApiName", var.api_gateway_name],
            ["AWS/ApiGateway", "Latency", "ApiName", var.api_gateway_name]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.region
          title   = "API Gateway Performance"
          period  = 60
        }
      }
    ]
  })
}

# IAM Role for Lambda functions
resource "aws_iam_role" "lambda_role" {
  name = "lambda-performance-testing-role-${var.environment}"

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
  name        = "lambda-performance-testing-policy-${var.environment}"
  description = "Policy for performance testing Lambda functions"

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
          "eks:DescribeCluster",
          "eks:ListClusters",
          "ec2:DescribeInstances",
          "autoscaling:DescribeAutoScalingGroups",
          "autoscaling:UpdateAutoScalingGroup",
          "autoscaling:SetDesiredCapacity",
          "cloudwatch:GetMetricData",
          "cloudwatch:PutMetricData",
          "cloudwatch:PutMetricAlarm",
          "ec2:DescribeInstanceTypes",
          "elasticloadbalancing:DescribeTargetGroups",
          "elasticloadbalancing:DescribeLoadBalancers"
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

# CloudWatch Event to trigger performance tests on schedule
resource "aws_cloudwatch_event_rule" "performance_test_schedule" {
  name                = "${var.project_name}-${var.environment}-performance-test-schedule"
  description         = "Trigger performance tests on schedule"
  schedule_expression = var.test_schedule_expression

  tags = local.tags
}

resource "aws_cloudwatch_event_target" "performance_test_target" {
  rule      = aws_cloudwatch_event_rule.performance_test_schedule.name
  target_id = "PerformanceTestLambda"
  arn       = aws_lambda_function.load_test_controller.arn
}

resource "aws_lambda_permission" "allow_cloudwatch_to_call_performance_test" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.load_test_controller.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.performance_test_schedule.arn
}