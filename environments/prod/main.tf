provider "aws" {
  region = var.region

  default_tags {
    tags = {
      Project     = var.project
      Environment = var.environment
      Owner       = var.owner
      CostCenter  = var.cost_center
    }
  }
}

terraform {
  required_version = ">= 1.0.0"

  # Using local state file for now
  # Will migrate to remote state later
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.10"
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.5"
    }
  }
}

# VPC Module
module "vpc" {
  source = "../../modules/vpc"
  
  project            = var.project
  environment        = var.environment
  region             = var.region
  vpc_cidr           = var.vpc_cidr
  public_subnet_cidr = var.public_subnet_cidr
  private_subnet_cidr = var.private_subnet_cidr
  db_subnet_cidr     = var.db_subnet_cidr
  availability_zone  = var.availability_zone
  tags               = var.tags
}

# EKS Module
module "eks" {
  source = "../../modules/eks"

  project            = var.project
  cluster_name       = "${var.project}-${var.environment}-cluster"
  environment        = var.environment
  region             = var.region
  vpc_id             = module.vpc.vpc_id
  subnet_ids         = [module.vpc.private_subnet_id, module.vpc.public_subnet_id]
  cluster_version    = var.cluster_version
  node_instance_types = var.node_instance_types
  node_desired_size  = var.node_desired_size
  node_max_size      = var.node_max_size
  node_min_size      = var.node_min_size
  tags               = var.tags
}

# Data source to get EKS cluster info
data "aws_eks_cluster" "eks" {
  name = module.eks.cluster_name
  depends_on = [module.eks]
}

# Data source for auth info
data "aws_eks_cluster_auth" "eks" {
  name = module.eks.cluster_name
  depends_on = [module.eks]
}

# Configure Kubernetes provider to access EKS cluster
provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.eks.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.eks.token
}

# Configure Helm provider
provider "helm" {
  kubernetes = {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.eks.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.eks.token
  }
}

# Monitoring Module
module "monitoring" {
  source = "../../modules/monitoring"
  
  project                 = var.project
  environment             = var.environment
  region                  = var.region
  cluster_name            = module.eks.cluster_name
  eks_cluster_endpoint    = module.eks.cluster_endpoint
  eks_oidc_provider_arn   = module.eks.oidc_provider_arn
  prometheus_namespace    = var.prometheus_namespace
  rancher_namespace       = var.rancher_namespace
  rancher_hostname        = var.rancher_hostname
  prometheus_storage_size = var.prometheus_storage_size
  grafana_storage_size    = var.grafana_storage_size
  tags                    = var.tags
  
  depends_on = [module.eks]
}

# CDN/Load Balancer Module
module "cdn" {
  source = "../../modules/cdn"

  project            = var.project
  environment        = var.environment
  region             = var.region
  domain_name        = var.domain_name
  alb_domains        = ["${module.eks.cluster_name}.${var.region}.elb.amazonaws.com"]
  acm_certificate_arn = "arn:aws:acm:us-east-1:123456789012:certificate/example" # Replace with actual ARN
  tags               = var.tags
}

# Provider for DR region
provider "aws" {
  alias  = "dr"
  region = var.dr_region
}

# VPC Module for DR
module "dr_vpc" {
  source = "../../modules/vpc"

  providers = {
    aws = aws.dr
  }

  project            = var.project
  environment        = "dr"
  region             = var.dr_region
  vpc_cidr           = var.dr_vpc_cidr
  public_subnet_cidr = var.dr_public_subnet_cidr
  private_subnet_cidr = var.dr_private_subnet_cidr
  db_subnet_cidr     = var.dr_db_subnet_cidr
  availability_zone  = var.dr_availability_zone
  tags               = merge(var.tags, { Environment = "dr" })
}

# DR Module
module "dr" {
  source = "../../modules/dr"

  project               = var.project
  environment           = "dr"
  region                = var.dr_region
  primary_region        = var.region
  domain_name           = var.domain_name
  primary_endpoint      = "${module.eks.cluster_name}.${var.region}.elb.amazonaws.com"
  dr_endpoint           = "dr-${module.eks.cluster_name}.${var.dr_region}.elb.amazonaws.com"
  health_check_path     = var.health_check_path
  health_check_interval = var.health_check_interval
  failover_threshold    = var.failover_threshold
  tags                  = merge(var.tags, { Environment = "dr" })
  cluster_name          = "${var.project}-dr-cluster"
  vpc_id                = module.dr_vpc.vpc_id
  subnet_ids            = [module.dr_vpc.private_subnet_id, module.dr_vpc.public_subnet_id]

  depends_on = [module.eks, module.cdn]
}

# Cost Optimization - AWS Budget
resource "aws_budgets_budget" "monthly" {
  name         = "${var.project}-${var.environment}-monthly-budget"
  budget_type  = "COST"
  limit_amount = var.monthly_budget_limit
  limit_unit   = "USD"
  time_unit    = "MONTHLY"

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 80
    threshold_type            = "PERCENTAGE"
    notification_type         = "ACTUAL"
    subscriber_email_addresses = [var.alert_email]
  }

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 100
    threshold_type            = "PERCENTAGE"
    notification_type         = "ACTUAL"
    subscriber_email_addresses = [var.alert_email]
  }
}

# SNS Topic for alerts
resource "aws_sns_topic" "alerts" {
  name = "${var.project}-${var.environment}-alerts"
}

resource "aws_sns_topic_subscription" "alerts_email" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

# Sustainability - CloudWatch alarms for resource utilization
resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  alarm_name          = "${var.project}-${var.environment}-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "300"
  statistic           = "Average"
  threshold           = "80"
  
  alarm_actions = [aws_sns_topic.alerts.arn]
}

resource "aws_cloudwatch_metric_alarm" "high_memory" {
  alarm_name          = "${var.project}-${var.environment}-high-memory"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "mem_used_percent"
  namespace           = "CWAgent"
  period              = "300"
  statistic           = "Average"
  threshold           = "80"
  
  alarm_actions = [aws_sns_topic.alerts.arn]
}

# Reliability - AWS Backup
resource "aws_backup_vault" "eks_backup" {
  name = "${var.project}-${var.environment}-backup-vault"
}

resource "aws_backup_plan" "eks_backup" {
  name = "${var.project}-${var.environment}-backup-plan"

  rule {
    rule_name         = "daily_backups"
    target_vault_name = aws_backup_vault.eks_backup.name
    schedule          = "cron(0 5 ? * * *)"  # Daily at 5 AM
    
    lifecycle {
      delete_after = 30
    }
  }
}

resource "aws_iam_role" "backup_role" {
  name = "${var.project}-${var.environment}-backup-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "backup.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "backup_policy" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForBackup"
  role       = aws_iam_role.backup_role.name
}

resource "aws_backup_selection" "eks_selection" {
  iam_role_arn = aws_iam_role.backup_role.arn
  name         = "${var.project}-${var.environment}-backup-selection"
  plan_id      = aws_backup_plan.eks_backup.id

  resources = [
    module.eks.cluster_arn
  ]
}

# Performance Efficiency - Auto Scaling Policy
resource "aws_autoscaling_policy" "cpu_scaling" {
  name                   = "${var.project}-${var.environment}-cpu-scaling"
  autoscaling_group_name = module.eks.node_group_autoscaling_group_name
  policy_type           = "TargetTrackingScaling"
  
  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = 70.0
  }
}