# Testing Modules for the Prod Environment

# Security Testing Module
module "security_testing" {
  source = "../../modules/testing/security_testing"

  region             = var.region
  environment        = var.environment
  project_name       = var.project
  vpc_id             = module.vpc.vpc_id
  eks_cluster_name   = module.eks.cluster_name
  notification_email = "security@example.com"
  
  # Prod-specific security testing parameters - more conservative
  enable_default_standards     = true
  enable_vpc_flow_log_analysis = true
  enable_db_security_assessment = true
  enable_simulated_pen_testing = false # Disable penetration testing in prod
  pen_test_targets             = []
}

# Reliability (DR) Testing Module
module "dr_testing" {
  source = "../../modules/testing/dr_testing"

  project_name       = var.project
  environment        = var.environment
  primary_region     = var.region
  dr_region          = var.dr_region
  vpc_cidr_primary   = var.vpc_cidr
  vpc_cidr_dr        = var.dr_vpc_cidr
  subnets_primary    = [var.public_subnet_cidr, var.private_subnet_cidr]
  subnets_dr         = [var.dr_public_subnet_cidr, var.dr_private_subnet_cidr]
  failover_components = ["eks", "rds", "elasticache", "api-gateway"]
  notification_email  = "operations@example.com"
  
  # Prod-specific DR testing parameters - stricter thresholds
  enable_network_disruption_test = false # No network disruption in prod
  rto_threshold_minutes = 15
  rpo_threshold_minutes = 15 # Much stricter RPO for prod
}

# Performance Efficiency Testing
module "performance_efficiency_testing" {
  source = "../../modules/testing/performance_efficiency"

  region          = var.region
  environment     = var.environment
  project_name    = var.project
  eks_cluster_name = module.eks.cluster_name
  load_test_endpoint = "https://${module.cdn.domain_name}/api/health"
  
  # Prod-specific performance parameters - more conservative
  target_node_count = 3
  scaling_test_duration_minutes = 10
  load_test_duration_minutes = 5
  load_test_users_per_second = 5 # Lower load for prod testing
  load_test_rps_target = 50
}

# Cost Optimization Testing
module "cost_optimization_testing" {
  source = "../../modules/testing/cost_optimization"

  region           = var.region
  environment      = var.environment
  project_name     = var.project
  notification_email = "finance@example.com"
  monthly_budget_amount = 15000 # Higher budget for prod
  
  # Prod-specific cost parameters
  cost_anomaly_threshold = 5 # Lower threshold to catch anomalies early
  idle_cpu_threshold = 10
  ec2_lookback_days = 30 # Longer analysis period for prod
}

# Operational Excellence Testing
module "operational_excellence_testing" {
  source = "../../modules/testing/operational_excellence"

  region           = var.region
  environment      = var.environment
  project_name     = var.project
  notification_email = "operations@example.com"
  jenkins_url      = "http://jenkins.${var.project}.${var.environment}.local"
  cloudtrail_name  = "${var.project}-${var.environment}-trail"
  github_repo      = "example-org/eks-aws-cicd"
  
  # Additional required runbooks for production
  required_runbooks = [
    "incident-response.md",
    "disaster-recovery.md",
    "deployment-procedure.md",
    "rollback-procedure.md",
    "scaling-procedure.md",
    "outage-communication.md",
    "data-breach-response.md"
  ]
}