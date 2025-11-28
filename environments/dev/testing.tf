# Testing Modules for the Dev Environment

# Security Testing Module
module "security_testing" {
  source = "../../modules/testing/security_testing"

  region             = var.region
  environment        = var.environment
  project_name       = var.project
  vpc_id             = module.vpc.vpc_id
  eks_cluster_name   = module.eks.cluster_name
  notification_email = "devops@example.com"
  
  # Dev-specific security testing parameters - more aggressive
  enable_default_standards     = true
  enable_vpc_flow_log_analysis = true
  enable_db_security_assessment = true
  enable_simulated_pen_testing = true # Enable penetration testing in dev only
  pen_test_targets             = ["${module.eks.cluster_endpoint}"]
}

# Reliability (DR) Testing Module
module "dr_testing" {
  source = "../../modules/testing/dr_testing"

  project_name       = var.project
  environment        = var.environment
  primary_region     = var.region
  dr_region          = "us-west-2" # Secondary region for DR testing
  vpc_cidr_primary   = var.vpc_cidr
  vpc_cidr_dr        = "10.1.0.0/16"
  subnets_primary    = [var.public_subnet_cidr, var.private_subnet_cidr]
  subnets_dr         = ["10.1.1.0/24", "10.1.2.0/24"]
  failover_components = ["eks", "rds", "elasticache"]
  notification_email  = "devops@example.com"
  
  # Dev-specific DR testing parameters - longer thresholds
  enable_network_disruption_test = true
  network_disruption_duration_minutes = 5
  rto_threshold_minutes = 30
  rpo_threshold_minutes = 60
}

# Performance Efficiency Testing
module "performance_efficiency_testing" {
  source = "../../modules/testing/performance_efficiency"

  region          = var.region
  environment     = var.environment
  project_name    = var.project
  eks_cluster_name = module.eks.cluster_name
  load_test_endpoint = "https://example-endpoint.${var.environment}.example.com/api/health"
  
  # Dev-specific performance parameters
  target_node_count = 5
  scaling_test_duration_minutes = 30
  load_test_duration_minutes = 15
  load_test_users_per_second = 20
  load_test_rps_target = 200
}

# Cost Optimization Testing
module "cost_optimization_testing" {
  source = "../../modules/testing/cost_optimization"

  region           = var.region
  environment      = var.environment
  project_name     = var.project
  notification_email = "finance@example.com"
  monthly_budget_amount = 5000
  
  # Dev-specific cost parameters
  cost_anomaly_threshold = 20
  idle_cpu_threshold = 5
  ec2_lookback_days = 7
}

# Operational Excellence Testing
module "operational_excellence_testing" {
  source = "../../modules/testing/operational_excellence"

  region           = var.region
  environment      = var.environment
  project_name     = var.project
  notification_email = "devops@example.com"
  jenkins_url      = "http://jenkins.${var.project}.${var.environment}.local"
  cloudtrail_name  = "${var.project}-${var.environment}-trail"
  github_repo      = "example-org/eks-aws-cicd"
}