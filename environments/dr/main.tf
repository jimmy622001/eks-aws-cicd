provider "aws" {
  region = var.region
}

# Provider for primary region (for DR integration)
provider "aws" {
  alias  = "primary"
  region = var.primary_region
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

  project             = var.project
  environment         = var.environment
  region              = var.region
  vpc_cidr            = var.vpc_cidr
  public_subnet_cidr  = var.public_subnet_cidr
  private_subnet_cidr = var.private_subnet_cidr
  db_subnet_cidr      = var.db_subnet_cidr
  availability_zone   = var.availability_zone
  tags                = var.tags
}

# EKS Module
module "eks" {
  source = "../../modules/eks"

  project             = var.project
  cluster_name        = "${var.project}-${var.environment}-cluster"
  environment         = var.environment
  region              = var.region
  vpc_id              = module.vpc.vpc_id
  subnet_ids          = [module.vpc.private_subnet_id, module.vpc.public_subnet_id]
  cluster_version     = var.cluster_version
  node_instance_types = var.node_instance_types
  node_desired_size   = var.node_desired_size
  node_max_size       = var.node_max_size
  node_min_size       = var.node_min_size
  tags                = var.tags
}

# Data source to get EKS cluster info
data "aws_eks_cluster" "eks" {
  name       = module.eks.cluster_name
  depends_on = [module.eks]
}

# Data source for auth info
data "aws_eks_cluster_auth" "eks" {
  name       = module.eks.cluster_name
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

# Get primary environment outputs
# Comment out for now as this requires the primary ALB to exist
# data "aws_lb" "primary" {
#   provider = aws.primary
#   name     = "primary-alb" # This should be dynamically determined
# }

# Use a placeholder value for now
locals {
  primary_endpoint = "placeholder-primary.elb.amazonaws.com"
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

# DR Module
module "dr" {
  source = "../../modules/dr"

  project               = var.project
  environment           = var.environment
  region                = var.region
  primary_region        = var.primary_region
  domain_name           = var.domain_name
  primary_endpoint      = local.primary_endpoint
  dr_endpoint           = "${module.eks.cluster_name}.${var.region}.elb.amazonaws.com"
  health_check_path     = var.health_check_path
  health_check_interval = var.health_check_interval
  failover_threshold    = var.failover_threshold
  tags                  = var.tags
  cluster_name          = module.eks.cluster_name
  vpc_id                = module.vpc.vpc_id
  subnet_ids            = [module.vpc.private_subnet_id, module.vpc.public_subnet_id]
}