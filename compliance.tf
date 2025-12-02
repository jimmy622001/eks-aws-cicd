# compliance.tf - Infrastructure compliance enforcement for Terraform Compliance platform
# This file defines resources and configurations that support automated compliance testing
# with Terraform Compliance framework (https://terraform-compliance.com/)

# AWS Config Resources for compliance monitoring and remediation
resource "aws_config_configuration_recorder" "compliance_recorder" {
  name     = "compliance-recorder"
  role_arn = aws_iam_role.config_recorder_role.arn
  
  recording_group {
    all_supported                 = true
    include_global_resource_types = true
  }
}

resource "aws_config_configuration_recorder_status" "compliance_recorder_status" {
  name       = aws_config_configuration_recorder.compliance_recorder.name
  is_enabled = true
}

resource "aws_config_delivery_channel" "compliance_channel" {
  name           = "compliance-delivery-channel"
  s3_bucket_name = aws_s3_bucket.compliance_logs.id
  
  snapshot_delivery_properties {
    delivery_frequency = "Six_Hours"
  }
  
  depends_on = [aws_config_configuration_recorder.compliance_recorder]
}

# S3 bucket for storing compliance data and reports
resource "aws_s3_bucket" "compliance_logs" {
  bucket = "eks-aws-cicd-compliance-logs-${var.environment}"
  
  lifecycle {
    prevent_destroy = true
  }
  
  tags = {
    Name        = "Compliance Logs"
    Environment = var.environment
    Purpose     = "Compliance Reporting"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "compliance_logs_encryption" {
  bucket = aws_s3_bucket.compliance_logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# IAM Role for Config recorder
resource "aws_iam_role" "config_recorder_role" {
  name = "compliance-config-recorder-role"

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

resource "aws_iam_role_policy_attachment" "config_role_policy" {
  role       = aws_iam_role.config_recorder_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSConfigRole"
}

# Define AWS Config Rules that align with compliance requirements
# These rules will be enforced and validated by Terraform Compliance

# 1. Ensure EKS clusters have audit logging enabled
resource "aws_config_config_rule" "eks_audit_logging" {
  name        = "eks-audit-logging-enabled"
  description = "Checks if Amazon EKS clusters have audit logging enabled for API server"

  source {
    owner             = "AWS"
    source_identifier = "EKS_CLUSTER_LOGGING_ENABLED"
  }
  
  input_parameters = jsonencode({
    loggingTypes = "api,audit,authenticator,controllerManager,scheduler"
  })
  
  depends_on = [aws_config_configuration_recorder.compliance_recorder]
}

# 2. Ensure EBS volumes are encrypted
resource "aws_config_config_rule" "encrypted_volumes" {
  name        = "encrypted-volumes"
  description = "Checks whether EBS volumes are encrypted"

  source {
    owner             = "AWS"
    source_identifier = "ENCRYPTED_VOLUMES"
  }
  
  depends_on = [aws_config_configuration_recorder.compliance_recorder]
}

# 3. Ensure S3 buckets have encryption enabled
resource "aws_config_config_rule" "s3_encryption" {
  name        = "s3-bucket-server-side-encryption-enabled"
  description = "Checks if S3 buckets have encryption enabled"

  source {
    owner             = "AWS"
    source_identifier = "S3_BUCKET_SERVER_SIDE_ENCRYPTION_ENABLED"
  }
  
  depends_on = [aws_config_configuration_recorder.compliance_recorder]
}

# 4. Ensure EKS clusters have restricted security group access
resource "aws_config_config_rule" "restricted_security_groups" {
  name        = "restricted-common-ports"
  description = "Checks if security groups allow unrestricted incoming traffic"

  source {
    owner             = "AWS"
    source_identifier = "RESTRICTED_INCOMING_TRAFFIC"
  }
  
  depends_on = [aws_config_configuration_recorder.compliance_recorder]
}

# 5. Ensure root user MFA is enabled
resource "aws_config_config_rule" "root_mfa" {
  name        = "root-account-mfa-enabled"
  description = "Checks if the root user has MFA enabled"

  source {
    owner             = "AWS"
    source_identifier = "ROOT_ACCOUNT_MFA_ENABLED"
  }
  
  depends_on = [aws_config_configuration_recorder.compliance_recorder]
}

# 6. Ensure IAM policies don't allow full '*:*' administrative privileges
resource "aws_config_config_rule" "iam_no_full_access" {
  name        = "iam-policy-no-statements-with-admin-access"
  description = "Checks IAM policies that grant full admin privileges"

  source {
    owner             = "AWS"
    source_identifier = "IAM_POLICY_NO_STATEMENTS_WITH_ADMIN_ACCESS"
  }
  
  depends_on = [aws_config_configuration_recorder.compliance_recorder]
}

# Integration with Security Hub for compliance reporting and visualization
resource "aws_securityhub_account" "compliance_hub" {
  count = var.environment == "prod" ? 1 : 0
}

# Enable specific security standards in Security Hub
resource "aws_securityhub_standards_subscription" "cis_aws_foundations" {
  count            = var.environment == "prod" ? 1 : 0
  standards_arn    = "arn:aws:securityhub:${data.aws_region.current.name}::standards/cis-aws-foundations-benchmark/v/1.2.0"
  depends_on       = [aws_securityhub_account.compliance_hub]
}

resource "aws_securityhub_standards_subscription" "aws_foundational_security" {
  count            = var.environment == "prod" ? 1 : 0
  standards_arn    = "arn:aws:securityhub:${data.aws_region.current.name}::standards/aws-foundational-security-best-practices/v/1.0.0"
  depends_on       = [aws_securityhub_account.compliance_hub]
}

# CloudWatch Event Rule to trigger compliance report generation
resource "aws_cloudwatch_event_rule" "compliance_report_generator" {
  name        = "compliance-report-schedule"
  description = "Triggers daily compliance report generation"
  
  schedule_expression = "cron(0 1 * * ? *)" # Run daily at 1 AM UTC
}

resource "aws_cloudwatch_event_target" "compliance_lambda_target" {
  rule      = aws_cloudwatch_event_rule.compliance_report_generator.name
  target_id = "ComplianceLambda"
  arn       = aws_lambda_function.compliance_reporter.arn
}

# Lambda function for compliance report generation
resource "aws_lambda_function" "compliance_reporter" {
  function_name = "compliance-reporter"
  handler       = "index.handler"
  runtime       = "nodejs16.x"
  role          = aws_iam_role.compliance_lambda_role.arn
  
  filename      = "${path.module}/modules/testing/compliance/lambda.zip"
  timeout       = 300
  
  environment {
    variables = {
      COMPLIANCE_BUCKET = aws_s3_bucket.compliance_logs.id
      ENVIRONMENT       = var.environment
    }
  }
}

# IAM Role for the compliance reporting Lambda
resource "aws_iam_role" "compliance_lambda_role" {
  name = "compliance-reporter-lambda-role"
  
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

# Custom policy for compliance Lambda to read Config and Security Hub data
resource "aws_iam_policy" "compliance_lambda_policy" {
  name        = "compliance-reporter-policy"
  description = "Policy for compliance reporter Lambda"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "config:GetComplianceDetailsByConfigRule",
          "config:DescribeComplianceByConfigRule",
          "securityhub:GetFindings",
          "s3:PutObject"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "compliance_lambda_policy_attachment" {
  role       = aws_iam_role.compliance_lambda_role.name
  policy_arn = aws_iam_policy.compliance_lambda_policy.arn
}

# Tag all compliance resources for visibility
locals {
  compliance_tags = {
    ComplianceManaged = "true"
    ComplianceFramework = "TerraformCompliance"
  }
}

# Data source for current region
data "aws_region" "current" {}