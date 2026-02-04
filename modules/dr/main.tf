# Variable declarations moved to variables.tf

provider "aws" {
  region = var.region
  alias  = "dr"
}

provider "aws" {
  region = var.primary_region
  alias  = "primary"
}

# IAM Role for EKS Cluster
resource "aws_iam_role" "eks_cluster_role" {
  provider = aws.dr
  name     = "${var.cluster_name}-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
      },
    ]
  })
}

# Attach necessary policies for EKS Cluster
resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  provider   = aws.dr
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_cluster_role.name
}

# IAM Role for EKS Node Group
resource "aws_iam_role" "eks_node_role" {
  provider = aws.dr
  name     = "${var.cluster_name}-node-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
}

# Attach necessary policies for EKS Node Group
resource "aws_iam_role_policy_attachment" "eks_worker_node_policy" {
  provider   = aws.dr
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks_node_role.name
}

resource "aws_iam_role_policy_attachment" "eks_cni_policy" {
  provider   = aws.dr
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks_node_role.name
}

resource "aws_iam_role_policy_attachment" "eks_container_registry_read" {
  provider   = aws.dr
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks_node_role.name
}

# CloudWatch Log Group for EKS Control Plane Logging
resource "aws_cloudwatch_log_group" "eks_logs" {
  provider          = aws.dr
  name              = "/aws/eks/${var.cluster_name}/cluster"
  retention_in_days = 7

  tags = {
    Environment = "dr"
    Name        = "${var.cluster_name}-logs"
  }
}

# KMS key for EKS secrets encryption
resource "aws_kms_key" "eks_secrets_key" {
  provider                = aws.dr
  description             = "KMS key for EKS cluster secrets encryption"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  tags = {
    Name        = "${var.cluster_name}-secrets-key"
    Environment = "dr"
  }
}

resource "aws_kms_alias" "eks_secrets_key_alias" {
  provider      = aws.dr
  name          = "alias/${var.cluster_name}-secrets-key"
  target_key_id = aws_kms_key.eks_secrets_key.key_id
}

# Add KMS permissions to EKS cluster role
resource "aws_iam_policy" "eks_kms_policy" {
  provider    = aws.dr
  name        = "${var.cluster_name}-kms-policy"
  description = "Policy to allow EKS to use KMS key for secrets encryption"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ]
        Effect   = "Allow"
        Resource = aws_kms_key.eks_secrets_key.arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "eks_kms_policy_attachment" {
  provider   = aws.dr
  policy_arn = aws_iam_policy.eks_kms_policy.arn
  role       = aws_iam_role.eks_cluster_role.name
}

# EKS Cluster for DR
resource "aws_eks_cluster" "dr" {
  provider = aws.dr
  name     = var.cluster_name
  role_arn = aws_iam_role.eks_cluster_role.arn

  vpc_config {
    subnet_ids             = var.subnet_ids
    endpoint_public_access  = false
    endpoint_private_access = true
  }

  encryption_config {
    resources = ["secrets"]
    provider {
      key_arn = aws_kms_key.eks_secrets_key.arn
    }
  }

  # Enable control plane logging for all log types as recommended by Snyk
  enabled_cluster_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_policy,
    aws_iam_role_policy_attachment.eks_kms_policy_attachment,
    aws_cloudwatch_log_group.eks_logs,
  ]

  tags = {
    Environment = "dr"
  }
}

# EKS Node Group with Spot Instances for DR
resource "aws_eks_node_group" "dr" {
  provider        = aws.dr
  cluster_name    = aws_eks_cluster.dr.name
  node_group_name = "${var.cluster_name}-node-group"
  node_role_arn   = aws_iam_role.eks_node_role.arn
  subnet_ids      = var.subnet_ids
  
  scaling_config {
    desired_size = 1
    min_size     = 1
    max_size     = 3
  }
  
  capacity_type  = "SPOT"
  instance_types = ["t3.medium"]
  
  depends_on = [
    aws_iam_role_policy_attachment.eks_worker_node_policy,
    aws_iam_role_policy_attachment.eks_cni_policy,
    aws_iam_role_policy_attachment.eks_container_registry_read,
  ]
  
  tags = {
    Environment = "dr"
  }
}

# Lambda IAM role for DR failover
resource "aws_iam_role" "lambda_failover_role" {
  provider = aws.dr
  name     = "lambda-failover-role"

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

# Attach necessary policies for Lambda
resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  provider   = aws.dr
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  role       = aws_iam_role.lambda_failover_role.name
}

resource "aws_iam_policy" "eks_update_policy" {
  provider    = aws.dr
  name        = "eks-update-policy"
  description = "Policy to allow Lambda to update EKS node groups"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "eks:UpdateNodegroupConfig",
          "eks:DescribeNodegroup",
          "eks:ListNodegroups",
          "eks:DescribeCluster"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
      {
        Action = [
          "autoscaling:SetDesiredCapacity",
          "autoscaling:DescribeAutoScalingGroups"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
      {
        Action = [
          "sns:Publish"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
      {
        Action = [
          "cloudwatch:PutMetricData"
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_eks_update" {
  provider   = aws.dr
  policy_arn = aws_iam_policy.eks_update_policy.arn
  role       = aws_iam_role.lambda_failover_role.name
}

# Create a new policy for Route53 health check management
resource "aws_iam_policy" "route53_health_check_policy" {
  provider    = aws.dr
  name        = "route53-health-check-policy"
  description = "Policy to allow Lambda to manage Route53 health checks"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "route53:GetHealthCheck",
          "route53:GetHealthCheckStatus",
          "route53:UpdateHealthCheck",
          "route53:GetHostedZone"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_route53_health_check" {
  provider   = aws.dr
  policy_arn = aws_iam_policy.route53_health_check_policy.arn
  role       = aws_iam_role.lambda_failover_role.name
}

# KMS key for SNS encryption
resource "aws_kms_key" "sns_encryption_key" {
  provider                = aws.dr
  description             = "KMS key for SNS topic encryption"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  tags = {
    Name        = "${var.cluster_name}-sns-key"
    Environment = "dr"
  }
}

resource "aws_kms_alias" "sns_encryption_key_alias" {
  provider      = aws.dr
  name          = "alias/dr/sns-encryption"
  target_key_id = aws_kms_key.sns_encryption_key.key_id
}

# Create SNS topic for DR alerts
resource "aws_sns_topic" "dr_alerts" {
  provider          = aws.dr
  name              = "dr-failover-alerts"
  kms_master_key_id = aws_kms_key.sns_encryption_key.arn

  tags = {
    Environment = "dr"
    Name        = "dr-alerts"
  }
}

# Archive file for spot to on-demand converter Lambda
data "archive_file" "spot_to_ondemand_zip" {
  type        = "zip"
  source_file = "${path.module}/lambda_functions/spot_to_ondemand.js"
  output_path = "${path.module}/spot_to_ondemand.zip"
}

# Archive file for failover tester Lambda
data "archive_file" "failover_tester_zip" {
  type        = "zip"
  source_file = "${path.module}/lambda_functions/failover_tester.js"
  output_path = "${path.module}/failover_tester.zip"
}

# Lambda function to change Spot to On-Demand instances when failover occurs
resource "aws_lambda_function" "spot_to_ondemand" {
  provider      = aws.dr
  function_name = "eks-spot-to-ondemand"
  role          = aws_iam_role.lambda_failover_role.arn
  handler       = "spot_to_ondemand.handler"
  runtime       = "nodejs18.x"
  timeout       = 120

  filename = data.archive_file.spot_to_ondemand_zip.output_path
  source_code_hash = data.archive_file.spot_to_ondemand_zip.output_base64sha256

  environment {
    variables = {
      CLUSTER_NAME     = aws_eks_cluster.dr.name
      NODE_GROUP_NAME  = aws_eks_node_group.dr.node_group_name
      REGION           = var.region
      SCALE_UP         = "true"
      DESIRED_SIZE     = "3"
      MIN_SIZE         = "2"
      MAX_SIZE         = "5"
      SNS_TOPIC_ARN    = aws_sns_topic.dr_alerts.arn
    }
  }
}

# Lambda function to test failover monthly
resource "aws_lambda_function" "failover_tester" {
  provider      = aws.dr
  function_name = "dr-failover-tester"
  role          = aws_iam_role.lambda_failover_role.arn
  handler       = "failover_tester.handler"
  runtime       = "nodejs18.x"
  timeout       = 300

  filename = data.archive_file.failover_tester_zip.output_path
  source_code_hash = data.archive_file.failover_tester_zip.output_base64sha256

  environment {
    variables = {
      PRIMARY_ENDPOINT = var.primary_endpoint
      DR_ENDPOINT      = var.dr_endpoint
      PRIMARY_REGION   = var.primary_region
      DR_REGION        = var.region
      HEALTH_CHECK_ID  = aws_route53_health_check.primary.id
      DOMAIN_NAME      = var.domain_name
      SNS_TOPIC_ARN    = aws_sns_topic.dr_alerts.arn
    }
  }
}

# Route53 Health Check for the primary endpoint
resource "aws_route53_health_check" "primary" {
  provider          = aws.primary
  fqdn              = var.primary_endpoint
  port              = 80
  type              = "HTTP"
  resource_path     = "/"
  failure_threshold = 3
  request_interval  = 30
  
  tags = {
    Name = "Primary-Health-Check"
  }
}

# Route53 Hosted Zone (assuming it already exists)
data "aws_route53_zone" "main" {
  provider = aws.primary
  name     = var.domain_name
}

# Route53 Record for Primary Region
resource "aws_route53_record" "primary" {
  provider = aws.primary
  zone_id  = data.aws_route53_zone.main.zone_id
  name     = "app.${var.domain_name}"
  type     = "A"
  
  failover_routing_policy {
    type = "PRIMARY"
  }
  
  set_identifier  = "primary"
  health_check_id = aws_route53_health_check.primary.id
  
  alias {
    name                   = var.primary_endpoint
    zone_id                = data.aws_route53_zone.main.zone_id
    evaluate_target_health = true
  }
}

# Route53 Record for DR Region
resource "aws_route53_record" "dr" {
  provider = aws.primary
  zone_id  = data.aws_route53_zone.main.zone_id
  name     = "app.${var.domain_name}"
  type     = "A"
  
  failover_routing_policy {
    type = "SECONDARY"
  }
  
  set_identifier = "dr"
  
  alias {
    name                   = var.dr_endpoint
    zone_id                = data.aws_route53_zone.main.zone_id
    evaluate_target_health = true
  }
}

# CloudWatch Event Rule to trigger Lambda when health check fails
resource "aws_cloudwatch_event_rule" "failover_event" {
  provider    = aws.dr
  name        = "failover-event-rule"
  description = "Triggers when primary region health check fails"

  event_pattern = jsonencode({
    source      = ["aws.route53"]
    detail-type = ["AWS Health Event"]
    detail      = {
      service       = ["ROUTE53"]
      eventTypeCode = ["AWS_ROUTE53_HEALTH_CHECK_FAILURE"]
    }
  })
}

# CloudWatch Event Target to connect event rule to Lambda
resource "aws_cloudwatch_event_target" "failover_lambda" {
  provider  = aws.dr
  rule      = aws_cloudwatch_event_rule.failover_event.name
  target_id = "FailoverLambda"
  arn       = aws_lambda_function.spot_to_ondemand.arn
}

# Lambda permission to allow CloudWatch Events to invoke it
resource "aws_lambda_permission" "allow_cloudwatch" {
  provider      = aws.dr
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.spot_to_ondemand.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.failover_event.arn
}

# CloudWatch Event Rule to run monthly DR failover tests
resource "aws_cloudwatch_event_rule" "monthly_dr_test" {
  provider    = aws.dr
  name        = "monthly-dr-test-rule"
  description = "Triggers monthly DR failover test"
  schedule_expression = "cron(0 8 1 * ? *)" # Run at 8:00 AM UTC on the 1st day of each month
}

# CloudWatch Event Target for monthly DR test
resource "aws_cloudwatch_event_target" "monthly_dr_test" {
  provider  = aws.dr
  rule      = aws_cloudwatch_event_rule.monthly_dr_test.name
  target_id = "MonthlyDRTest"
  arn       = aws_lambda_function.failover_tester.arn
}

# Lambda permission for monthly DR test
resource "aws_lambda_permission" "allow_monthly_test" {
  provider      = aws.dr
  statement_id  = "AllowExecutionFromCloudWatchMonthly"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.failover_tester.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.monthly_dr_test.arn
}

# Create directories for lambda functions if they don't exist
resource "local_file" "ensure_lambda_dir" {
  content  = ""
  filename = "${path.module}/lambda_functions/.gitkeep"
}

# Ensure lambda functions directory exists
resource "null_resource" "ensure_lambda_functions" {
  triggers = {
    always_run = timestamp()
  }

  provisioner "local-exec" {
    command = "mkdir -p ${path.module}/lambda_functions"
    interpreter = ["/bin/bash", "-c"]
  }
}

output "dr_cluster_id" {
  value = aws_eks_cluster.dr.id
}

output "dr_cluster_name" {
  value = aws_eks_cluster.dr.name
}

output "dr_cluster_endpoint" {
  value = aws_eks_cluster.dr.endpoint
}

output "dr_failover_lambda" {
  value = aws_lambda_function.spot_to_ondemand.arn
}

output "dr_test_lambda" {
  value = aws_lambda_function.failover_tester.arn
}

output "dr_sns_topic" {
  value = aws_sns_topic.dr_alerts.arn
}