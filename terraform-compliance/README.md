# Terraform Compliance Testing

This directory contains features and configurations for running Terraform Compliance tests against your infrastructure.

## Overview

Terraform Compliance is a BDD (Behavior Driven Development) test framework for Terraform. It allows you to write tests that verify your infrastructure meets security, compliance, and organizational requirements.

## Feature Files

The `features/` directory contains BDD-style feature files that define compliance rules:

- `eks_security.feature` - Compliance tests for EKS clusters
- `s3_security.feature` - Compliance tests for S3 buckets

## Environment-Specific Testing

### How It Works

The compliance testing framework allows you to test specific environments (development, staging, production) by targeting the appropriate Terraform configuration for that environment.

### Running Tests for Specific Environments

To run compliance tests for a specific environment:

```bash
./pipelines/testing/run-terraform-compliance.sh -e <environment>
Where <environment> is one of:

dev - Development environment
staging - Staging/QA environment
prod - Production environment
Examples
Test development environment:

./pipelines/testing/run-terraform-compliance.sh -e dev
Test production environment with stricter compliance checks:

./pipelines/testing/run-terraform-compliance.sh -e prod --strict
How Environment Targeting Works
The script retrieves the Terraform configuration for the specified environment
It runs terraform plan to generate a plan file for that environment
Terraform Compliance tests are executed against that plan file
Results indicate whether the specified environment's infrastructure meets compliance requirements
Troubleshooting
Environment not found: Verify the environment name matches your Terraform workspace or environment folder structure
Failed compliance checks: Review the output to identify specific compliance issues in that environment
Permission issues: Ensure you have appropriate AWS credentials for the target environment

## 2. modules/testing/USAGE.md (Additions to be merged with existing content)

```markdown
## Optional Compliance Testing

In addition to the standard security tests, this framework includes optional compliance testing using Terraform Compliance. These tests verify that your infrastructure meets security and compliance requirements.

### Running Environment-Specific Compliance Tests

You can run compliance tests against specific environments to ensure each one meets its required compliance standards:

```bash
# Test development environment
./pipelines/testing/run-terraform-compliance.sh -e dev

# Test staging environment
./pipelines/testing/run-terraform-compliance.sh -e staging

# Test production environment
./pipelines/testing/run-terraform-compliance.sh -e prod
When to Run Compliance Tests
Compliance tests are valuable in several scenarios:

Before deploying to a new environment
After making significant infrastructure changes
During security audits
As part of pre-production verification
Integration with CI/CD
You can integrate compliance testing into your CI/CD pipeline by adding the following stage:

stage('Compliance Testing') {
  when { expression { params.RUN_COMPLIANCE_TESTS } }
  steps {
    sh "./pipelines/testing/run-terraform-compliance.sh -e ${params.ENVIRONMENT}"
  }
}
For more detailed information, see the documentation in the terraform-compliance directory.