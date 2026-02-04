# This file is a placeholder for the root module.
# It can be used to set up common providers and backend.

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 3.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.0"
    }
  }
}

# Instructions to set up the environment
output "setup_instructions" {
  value = <<EOF
    
    ===== EKS Jenkins BitBucket Infrastructure Setup =====
    
    The project is organized as follows:
    
    1. Infrastructure Components:
       - VPC with public, private, and database subnets
       - EKS clusters for development, production, and disaster recovery
       - Jenkins server with autoscaling agents in the dev cluster
       - Monitoring with Prometheus and Grafana
       - Rancher for cluster management
       - CDN with load balancer for traffic distribution
    
    2. Environment-Specific Configurations:
       - Development (dev): Scaled-down EKS cluster for development
       - Production (prod): Full-capacity EKS cluster for production
       - Disaster Recovery (dr): Spot instances in a different region
    
    3. Deployment Instructions:
    
       a. Create S3 buckets for Terraform state:
          - terraform-state-eks-jenkins-bit-dev
          - terraform-state-eks-jenkins-bit-prod
          - terraform-state-eks-jenkins-bit-dr
    
       b. Set up Jenkins credentials:
          - AWS credentials (aws-credentials)
          - AWS account ID (aws-account-id)
    
       c. Create Jenkins pipelines:
          - infra-pipeline: Use pipelines/infra/Jenkinsfile
          - eks-pipeline: Use pipelines/eks/Jenkinsfile
          - app-pipeline: Use pipelines/app/Jenkinsfile
    
       d. Deployment Flow:
          1. Run infra-pipeline to set up the VPC
          2. Run eks-pipeline to set up the EKS cluster
          3. Run app-pipeline to deploy the application
    
    4. CI/CD Workflow:
       - Development: Commits to development branch trigger deployment to dev environment
       - Production: Merges to main branch trigger deployment to production environment with approval
       - DR: Failover is handled by Route53 health checks and Lambda functions
    
    5. Scaling:
       - Jenkins agents are scaled based on build workload
       - Applications are scaled using Kubernetes HPA
       - DR environment uses spot instances which are converted to on-demand during failover
  EOF
}