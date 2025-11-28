# Testing Modules Reusability Guide

This document provides instructions on how to reuse the testing modules from this project in other AWS infrastructure projects. These testing modules are designed to be modular, flexible, and adaptable to different environments and project structures.

## Table of Contents

1. [Overview of Testing Modules](#overview-of-testing-modules)
2. [Prerequisites](#prerequisites)
3. [Step-by-Step Integration Guide](#step-by-step-integration-guide)
4. [Environment-Specific Configuration](#environment-specific-configuration)
5. [Pipeline Integration](#pipeline-integration)
6. [Customization Points](#customization-points)
7. [Troubleshooting](#troubleshooting)

## Overview of Testing Modules

This project contains the following testing modules:

- **Security Testing**: Evaluates security posture and compliance
- **DR Testing**: Tests disaster recovery capabilities and failover procedures
- **Performance Testing**: Evaluates application and infrastructure performance
- **Cost Optimization**: Analyzes and optimizes resource costs
- **Operational Excellence**: Tests operational procedures and monitoring

Each module is self-contained with its own variables, resources, and outputs.

## Prerequisites

Before integrating these testing modules into a new project, ensure you have:

1. A Terraform-based AWS infrastructure project
2. Access to AWS accounts for development and production environments
3. IAM permissions to create and manage testing resources
4. CI/CD pipeline integration capability (Jenkins recommended)

## Step-by-Step Integration Guide

### 1. Copy the Testing Module Structure

```bash
# Create a backup of your existing modules directory (if needed)
cp -r /path/to/existing-project/modules /path/to/existing-project/modules.bak

# Copy the testing modules to your project
cp -r modules/testing/ /path/to/new-project/modules/
```

### 2. Copy the Pipeline Definitions

```bash
# Copy the pipeline configurations
mkdir -p /path/to/new-project/pipelines/testing
cp -r pipelines/testing/* /path/to/new-project/pipelines/testing/
```

### 3. Create Environment-Specific Configurations

For each environment in your project (dev, staging, prod, etc.), create a `testing.tf` file:

#### Example for Development Environment

Create `/path/to/new-project/environments/dev/testing.tf`:

```terraform
# Security Testing Module
module "security_testing" {
  source = "../../modules/testing/security_testing"

  region             = var.region
  environment        = "dev"
  project_name       = var.project_name
  vpc_id             = module.network.vpc_id  # Update with your VPC reference
  eks_cluster_name   = module.kubernetes.cluster_name  # Update with your EKS reference
  notification_email = "team-dev@yourcompany.com"
  
  # Development-specific parameters
  enable_simulated_pen_testing = true
  scan_frequency               = "daily"
}

# DR Testing Module
module "dr_testing" {
  source = "../../modules/testing/dr_testing"

  primary_region     = var.region
  dr_region          = var.dr_region
  environment        = "dev"
  project_name       = var.project_name
  notification_email = "team-dev@yourcompany.com"
  
  # RTO/RPO targets for development
  rto_target_minutes = 30
  rpo_target_minutes = 15
}

# Add other testing modules as needed
```

#### Example for Production Environment

Create `/path/to/new-project/environments/prod/testing.tf`:

```terraform
# Security Testing Module
module "security_testing" {
  source = "../../modules/testing/security_testing"

  region             = var.region
  environment        = "prod"
  project_name       = var.project_name
  vpc_id             = module.network.vpc_id
  eks_cluster_name   = module.kubernetes.cluster_name
  notification_email = "team-prod@yourcompany.com,security@yourcompany.com"
  
  # Production-specific parameters
  enable_simulated_pen_testing = false
  scan_frequency               = "weekly"
}

# DR Testing Module
module "dr_testing" {
  source = "../../modules/testing/dr_testing"

  primary_region     = var.region
  dr_region          = var.dr_region
  environment        = "prod"
  project_name       = var.project_name
  notification_email = "team-prod@yourcompany.com,operations@yourcompany.com"
  
  # Stricter RTO/RPO targets for production
  rto_target_minutes = 15
  rpo_target_minutes = 5
}

# Add other testing modules as needed
```

## Environment-Specific Configuration

Each testing module should be configured according to the requirements of specific environments:

| Parameter | Development | Production |
|-----------|------------|------------|
| Notification Recipients | Development team | Production team, Security/Ops teams |
| Testing Frequency | More frequent | Less frequent, scheduled maintenance |
| Testing Scope | Broader, exploratory | Targeted, critical paths |
| Thresholds | More lenient | Stricter |

## Pipeline Integration

### 1. Configure Jenkins Pipeline

Update your Jenkinsfile to include the testing pipelines:

1. Copy the pipeline files to your Jenkins configuration:
   ```bash
   cp pipelines/testing/dr-Jenkinsfile /path/to/jenkins/pipelines/
   cp pipelines/testing/security-Jenkinsfile /path/to/jenkins/pipelines/
   ```

2. Create Jenkins pipeline jobs that reference these files

3. Configure the parameters for your project:
   - `ENVIRONMENT` (dev, staging, prod)
   - `AWS_REGION` 
   - `PROJECT_NAME`

### 2. Schedule Automated Tests

Configure Jenkins to run tests on a schedule:

```groovy
pipeline {
    agent any
    
    triggers {
        // Run weekly DR tests
        cron('0 0 * * 0')  // Every Sunday at midnight
    }
    
    parameters {
        choice(name: 'ENVIRONMENT', choices: ['dev', 'prod'], description: 'Environment to test')
        string(name: 'AWS_REGION', defaultValue: 'us-west-2', description: 'AWS Region')
    }
    
    stages {
        stage('Run DR Tests') {
            steps {
                sh "terraform -chdir=environments/${params.ENVIRONMENT} init"
                sh "terraform -chdir=environments/${params.ENVIRONMENT} apply -target=module.dr_testing -auto-approve"
            }
        }
    }
}
```

## Customization Points

When adapting these modules for a new project, consider customizing:

### 1. Project-Specific Resources

Update references to specific resources based on your project structure:

```terraform
# Original
vpc_id = module.eks.vpc_id

# Updated for new project
vpc_id = module.network.vpc_id
```

### 2. Regional Configuration

Set your project's primary and DR regions:

```terraform
# For multi-region projects
primary_region = "us-west-2"
dr_region      = "us-east-1"
```

### 3. Test Parameters

Adjust thresholds based on your project's requirements:

```terraform
# Customize RTO/RPO targets
rto_target_minutes = 15  # Your project's requirement
rpo_target_minutes = 5   # Your project's requirement
```

### 4. Notification Endpoints

Update notification destinations:

```terraform
# For your organization
notification_email = "your-team@yourcompany.com"
slack_webhook_url  = "https://hooks.slack.com/services/YOUR/WEBHOOK/PATH"
```

## Troubleshooting

If you encounter issues when integrating these testing modules:

1. **Module Not Found**: Ensure the module path is correct relative to your environment directory
2. **Resource Not Found**: Check that referenced resources (VPCs, EKS clusters) exist and are correctly referenced
3. **IAM Permissions**: Verify the executing role has permissions to create and manage testing resources
4. **Pipeline Failures**: Check Jenkins console output for specific errors

## Example Project Structure After Integration

```
your-project/
├── environments/
│   ├── dev/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── testing.tf  # Added testing configuration
│   └── prod/
│       ├── main.tf
│       ├── variables.tf
│       └── testing.tf  # Added testing configuration
├── modules/
│   ├── networking/
│   ├── kubernetes/
│   └── testing/        # Copied testing modules
│       ├── security_testing/
│       ├── dr_testing/
│       └── ...
└── pipelines/
    ├── main-pipeline.jenkinsfile
    └── testing/        # Copied pipeline definitions
        ├── dr-Jenkinsfile
        └── security-Jenkinsfile
```

By following this guide, you should be able to successfully integrate these testing modules into any AWS infrastructure project managed by Terraform.