# Running Testing Modules

This document provides instructions for running the architecture testing modules in both development and production environments.

## Available Testing Modules

The following testing modules are available:

1. `security_testing` - Tests for security compliance and vulnerabilities
2. `dr_testing` - Tests for disaster recovery capabilities
3. `performance_efficiency_testing` - Tests for performance efficiency
4. `cost_optimization_testing` - Tests for cost optimization
5. `operational_excellence_testing` - Tests for operational excellence

## Running Tests in Development Environment

```bash
# Navigate to the dev environment directory
cd environments/dev

# Run a specific testing module
terraform apply -target=module.security_testing

# Or run all testing modules at once
terraform apply

# Destroy testing resources when done
terraform destroy -target=module.security_testing
```

## Running Tests in Production Environment

```bash
# Navigate to the prod environment directory
cd environments/prod

# Run a specific testing module (with caution in production!)
terraform apply -target=module.security_testing

# Or run all testing modules at once
terraform apply

# Destroy testing resources when done
terraform destroy -target=module.security_testing
```

## Key Differences Between Environments

### Dev Environment Testing:
- Includes more aggressive testing such as penetration testing
- Allows network disruption testing for DR
- Has longer RTO/RPO thresholds
- Uses higher load for performance testing

### Production Environment Testing:
- Excludes disruptive tests like penetration testing
- Disables network disruption testing
- Has stricter RTO/RPO thresholds
- Uses lower load for performance testing
- Has more extensive monitoring for all tests

## Automated Testing via Jenkins

The testing modules can be run automatically using the Jenkins pipelines:

1. For security testing: `pipelines/testing/security-Jenkinsfile`
2. For DR testing: `pipelines/testing/dr-Jenkinsfile`

These pipelines can be scheduled to run periodically or triggered manually from Jenkins.

## Test Results

Test results are sent to:
1. Email notifications (configured per environment)
2. CloudWatch dashboards
3. SNS topics for integration with other notification systems
4. S3 storage for historical analysis

