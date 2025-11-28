/**
 * DR Testing Module
 * This module implements comprehensive disaster recovery testing capabilities
 * Covers AWS Well-Architected Framework Reliability Pillar
 */

# AWS provider configuration
provider "aws" {
  region = var.primary_region
  alias  = "primary"
}

provider "aws" {
  region = var.dr_region
  alias  = "dr"
}

# FIS experiment template for DR testing
resource "aws_fis_experiment_template" "dr_test" {
  provider = aws.primary

  description = "DR Failover Test for ${var.project_name}"
  role_arn   = aws_iam_role.fis_role.arn

  stop_condition {
    source = "aws:cloudwatch:alarm"
    value  = aws_cloudwatch_metric_alarm.test_duration.arn
  }

  action {
    name      = "failover-test"
    action_id = "aws:eks:inject-kubernetes-custom-resource"

    parameter {
      key   = "duration"
      value = "${var.test_timeout_minutes}m"
    }

    target {
      key   = "Clusters"
      value = "eks-clusters"
    }
  }

  target {
    name      = "eks-clusters"
    resource_type = "aws:eks:cluster"
    selection_mode = "ALL"

    filter {
      path   = "State"
      values = ["ACTIVE"]
    }
  }

  tags = {
    Name = "DR-Test-${var.project_name}"
  }
}

# Network Connectivity Disruption Test
resource "aws_fis_experiment_template" "network_disruption_test" {
  count     = var.enable_network_disruption_test ? 1 : 0
  provider  = aws.primary

  description = "Network Disruption Test for ${var.project_name}"
  role_arn   = aws_iam_role.fis_role.arn

  stop_condition {
    source = "aws:cloudwatch:alarm"
    value  = aws_cloudwatch_metric_alarm.test_duration.arn
  }

  action {
    name      = "network-disruption"
    action_id = "aws:network:disrupt-connectivity"

    parameter {
      key   = "duration"
      value = "${var.network_disruption_duration_minutes}m"
    }

    parameter {
      key   = "scope"
      value = "availability-zone"
    }

    target {
      key   = "Subnets"
      value = "target-subnets"
    }
  }

  target {
    name          = "target-subnets"
    resource_type = "aws:ec2:subnet"
    selection_mode = "COUNT(1)"
  
    filter {
      path   = "tag:Environment"
      values = [var.environment]
    }
  }

  tags = {
    Name = "Network-Disruption-Test-${var.project_name}"
  }
}

# Data Integrity and RPO Validation
resource "aws_lambda_function" "rpo_validator" {
  function_name = "${var.project_name}-rpo-validator"
  role          = aws_iam_role.lambda_role.arn
  handler       = "rpo-validator.handler"
  runtime       = "nodejs16.x"
  timeout       = 300

  filename      = "${path.module}/lambda/rpo_validator.zip"

  environment {
    variables = {
      PRIMARY_REGION = var.primary_region
      DR_REGION      = var.dr_region
      PROJECT_NAME   = var.project_name
      ENVIRONMENT    = var.environment
      TARGET_RPO     = var.target_rpo_seconds
    }
  }
}

# RTO Validation Test
resource "aws_lambda_function" "rto_validator" {
  function_name = "${var.project_name}-rto-validator"
  role          = aws_iam_role.lambda_role.arn
  handler       = "rto-validator.handler"
  runtime       = "nodejs16.x"
  timeout       = 300

  filename      = "${path.module}/lambda/rto_validator.zip"

  environment {
    variables = {
      PRIMARY_REGION  = var.primary_region
      DR_REGION       = var.dr_region
      PROJECT_NAME    = var.project_name
      ENVIRONMENT     = var.environment
      TARGET_RTO      = var.target_rto_minutes
    }
  }
}

# CloudWatch alarm for test duration
resource "aws_cloudwatch_metric_alarm" "test_duration" {
  provider            = aws.primary
  alarm_name          = "dr-test-duration-exceeded"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "DRTestDuration"
  namespace           = "Custom/DR"
  period              = var.test_timeout_minutes * 60
  statistic           = "Maximum"
  threshold           = var.test_timeout_minutes
  alarm_description   = "This metric monitors DR test duration"
}

# Create placeholder Lambda zip files if they don't exist
resource "local_file" "rpo_validator_zip" {
  filename = "${path.module}/lambda/rpo_validator.zip"
  content  = "UEsFBgAAAAAAAAAAAAAAAAAAAAAAAA==" # Empty zip file
  provisioner "local-exec" {
    command = "mkdir -p ${path.module}/lambda"
  }
}

resource "local_file" "rto_validator_zip" {
  filename = "${path.module}/lambda/rto_validator.zip"
  content  = "UEsFBgAAAAAAAAAAAAAAAAAAAAAAAA==" # Empty zip file
  provisioner "local-exec" {
    command = "mkdir -p ${path.module}/lambda"
  }
}

# IAM role for FIS
resource "aws_iam_role" "fis_role" {
  provider = aws.primary
  name = "fis-dr-testing-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "fis.amazonaws.com"
        }
      },
    ]
  })
}

# IAM role for Lambda functions
resource "aws_iam_role" "lambda_role" {
  provider = aws.primary
  name = "lambda-dr-testing-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_policy" "lambda_policy" {
  provider = aws.primary
  name        = "lambda-dr-testing-policy"
  description = "Policy for Lambda functions to execute DR validation tests"

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
        Resource = "*"
      },
      {
        Action = [
          "dynamodb:DescribeTable",
          "dynamodb:Scan",
          "dynamodb:Query",
          "rds:DescribeDBInstances",
          "rds:DescribeDBClusters",
          "elasticache:DescribeCacheClusters"
        ],
        Effect   = "Allow",
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_policy_attach" {
  provider   = aws.primary
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_policy.arn
}

resource "aws_iam_policy" "fis_policy" {
  provider = aws.primary
  name        = "fis-dr-testing-policy"
  description = "Policy for FIS to execute DR tests"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "eks:DescribeCluster",
          "eks:ListClusters",
          "ec2:DescribeSubnets",
          "ec2:DescribeRouteTables",
          "ec2:DescribeNetworkAcls",
          "ec2:DescribeSecurityGroups",
          "network-firewall:ListFirewalls"
        ],
        Effect   = "Allow",
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "fis_policy_attach" {
  provider   = aws.primary
  role       = aws_iam_role.fis_role.name
  policy_arn = aws_iam_policy.fis_policy.arn
}