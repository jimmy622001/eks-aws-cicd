/**
 * Security Testing Module
 * This module implements comprehensive security testing for infrastructure
 * Covers AWS Well-Architected Framework Security Pillar
 */

# AWS provider configuration
provider "aws" {
  region = var.region
}

# Security Hub enablement
resource "aws_securityhub_account" "security_hub" {
  enable_default_standards = var.enable_default_standards
}

# GuardDuty enablement
resource "aws_guardduty_detector" "main" {
  enable                       = true
  finding_publishing_frequency = "SIX_HOURS"
}

# AWS Config enablement
resource "aws_config_configuration_recorder" "config" {
  name     = "${var.project_name}-config-recorder"
  role_arn = aws_iam_role.config_role.arn

  recording_group {
    all_supported                 = true
    include_global_resource_types = true
  }
}

resource "aws_config_configuration_recorder_status" "config" {
  name       = aws_config_configuration_recorder.config.name
  is_enabled = true
}

resource "aws_config_delivery_channel" "config" {
  name           = "${var.project_name}-config-delivery-channel"
  s3_bucket_name = aws_s3_bucket.config_logs.bucket

  snapshot_delivery_properties {
    delivery_frequency = "Six_Hours"
  }
}

# S3 Bucket for Config Logs
resource "aws_s3_bucket" "config_logs" {
  bucket = "${var.project_name}-config-logs-${var.environment}"

  tags = {
    Name        = "${var.project_name}-config-logs"
    Environment = var.environment
  }
}

resource "aws_s3_bucket_public_access_block" "config_logs" {
  bucket = aws_s3_bucket.config_logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# IAM Role for Config
resource "aws_iam_role" "config_role" {
  name = "aws-config-role-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "config.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "config_policy_attach" {
  role       = aws_iam_role.config_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWS_ConfigRole"
}

# Security testing with Inspector
resource "aws_inspector2_enabler" "inspector" {
  account_ids    = [data.aws_caller_identity.current.account_id]
  resource_types = ["EC2", "ECR", "LAMBDA", "LAMBDA_CODE"]
}

# IAM Access Analyzer for identity-based security
resource "aws_accessanalyzer_analyzer" "analyzer" {
  analyzer_name = "${var.project_name}-iam-analyzer"
  type          = "ACCOUNT"
}

# VPC Flow Log Analysis
resource "aws_flow_log" "vpc_flow_log" {
  count                = var.enable_vpc_flow_log_analysis ? 1 : 0
  log_destination      = aws_s3_bucket.config_logs.arn
  log_destination_type = "s3"
  traffic_type         = "ALL"
  vpc_id               = var.vpc_id
}

# Database Security Assessment
resource "aws_lambda_function" "db_security_scanner" {
  count         = var.enable_db_security_assessment ? 1 : 0
  function_name = "${var.project_name}-db-security-scanner"
  role          = aws_iam_role.lambda_role.arn
  handler       = "db-scanner.handler"
  runtime       = "nodejs16.x"
  timeout       = 300

  filename      = "${path.module}/lambda/db_security_scanner.zip"

  environment {
    variables = {
      ENVIRONMENT  = var.environment
      PROJECT_NAME = var.project_name
    }
  }
}

# S3 Bucket Security Assessment
resource "aws_lambda_function" "s3_security_scanner" {
  function_name = "${var.project_name}-s3-security-scanner"
  role          = aws_iam_role.lambda_role.arn
  handler       = "s3-scanner.handler"
  runtime       = "nodejs16.x"
  timeout       = 300

  filename      = "${path.module}/lambda/s3_security_scanner.zip"

  environment {
    variables = {
      ENVIRONMENT  = var.environment
      PROJECT_NAME = var.project_name
    }
  }
}

# Penetration Testing Lambda (simulated)
resource "aws_lambda_function" "pen_test_scanner" {
  count         = var.enable_simulated_pen_testing ? 1 : 0
  function_name = "${var.project_name}-pen-test-scanner"
  role          = aws_iam_role.lambda_role.arn
  handler       = "pen-test.handler"
  runtime       = "nodejs16.x"
  timeout       = 300

  filename      = "${path.module}/lambda/pen_test_scanner.zip"

  environment {
    variables = {
      ENVIRONMENT  = var.environment
      PROJECT_NAME = var.project_name
      TARGET_URLS  = jsonencode(var.pen_test_targets)
    }
  }
}
# Get current account ID
data "aws_caller_identity" "current" {}

# Lambda function for security scanning
resource "aws_lambda_function" "security_scanner" {
  function_name = "${var.project_name}-security-scanner"
  role          = aws_iam_role.lambda_role.arn
  handler       = "index.handler"
  runtime       = "nodejs16.x"
  timeout       = 300
  
  filename      = "${path.module}/lambda/security_scanner.zip"
  
  environment {
    variables = {
      ENVIRONMENT  = var.environment
      PROJECT_NAME = var.project_name
      REGION       = var.region
    }
  }
}

# IAM Role for Lambda
resource "aws_iam_role" "lambda_role" {
  name = "lambda-security-scanner-role-${var.environment}"

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
}

resource "aws_iam_policy" "lambda_policy" {
  name        = "lambda-security-scanner-policy-${var.environment}"
  description = "Policy for security scanner Lambda"

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
          "ec2:DescribeInstances",
          "eks:DescribeCluster",
          "ecr:DescribeRepositories",
          "cloudtrail:LookupEvents",
          "rds:DescribeDBInstances",
          "rds:DescribeDBClusters",
          "s3:GetBucketPolicy",
          "s3:GetBucketAcl",
          "s3:ListBucket",
          "iam:GetAccountSummary",
          "iam:ListUsers",
          "iam:ListRoles",
          "accessanalyzer:ListFindings",
          "securityhub:GetFindings",
          "guardduty:ListFindings"
        ],
        Effect   = "Allow",
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_policy_attach" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_policy.arn
}