# AWS Infrastructure Testing Module

## Overview

This testing module provides comprehensive testing frameworks and methodologies to ensure AWS infrastructure compliance with the AWS Well-Architected Framework pillars and validate disaster recovery capabilities. The module includes automated testing pipelines, disaster recovery testing playbooks, and detailed operational runbooks.

> **Important Update**: All testing pipelines are now available as GitHub Actions workflows in the `.github/workflows` directory, providing a more integrated and accessible testing experience.

## Key Components

### Testing Pipelines

- **Infrastructure Compliance Testing**: Automated pipeline that validates AWS infrastructure against the AWS Well-Architected Framework pillars:
    - Operational Excellence
    - Security
    - Reliability
    - Performance Efficiency
    - Cost Optimization
    - Sustainability

- **Disaster Recovery Testing**: Pipeline specifically designed to validate DR capabilities and measure recovery metrics.

### Disaster Recovery Playbooks and Runbooks

Recently added comprehensive documentation for DR testing:

1. **Incident Response Runbook** (`incident-response.md`)
    - Structured approach to incident classification
    - Detailed response procedures for different incident types
    - Clear escalation paths and communication protocols
    - Post-incident analysis framework

2. **Test Environment Setup** (`test-environment-setup.md`)
    - AWS environment provisioning procedures for testing
    - Infrastructure-as-Code templates for consistent environments
    - Pre-test validation procedures
    - Test data management

3. **Test Execution Procedures** (`test-execution.md`)
    - Step-by-step test execution guidelines
    - Success criteria definition
    - Metrics collection and analysis
    - Post-test validation

## Testing Coverage

This testing module provides extensive coverage across multiple domains:

### AWS Services Tested

- Compute (EC2, EKS)
- Storage (S3, EBS)
- Database (RDS, DynamoDB)
- Networking (VPC, Security Groups, Load Balancers)
- Security (IAM, KMS)
- Monitoring (CloudWatch)

### Testing Methodologies

1. **Compliance Testing**
    - Automated policy validation
    - Security control verification
    - Best practice adherence

2. **Disaster Recovery Testing**
    - Recovery Time Objective (RTO) validation
    - Recovery Point Objective (RPO) validation
    - Failover automation testing
    - Data integrity verification

3. **Operational Acceptance Testing (OAT)**
    - Monitoring & logging verification
    - Backup procedure validation
    - Performance under stress
    - Security controls validation

## Alignment with AWS Best Practices

This testing module is designed to align with:

- AWS Well-Architected Framework
- AWS Reliability Pillar whitepaper
- AWS Security Best Practices
- AWS Disaster Recovery approaches (Backup & Restore, Pilot Light, Warm Standby, Multi-Site)

## Quick Start

For new users, here are the most common ways to get started with testing:

### Using GitHub Actions (Recommended)

1. Run the compliance test workflow:
   - Go to Actions tab in GitHub
   - Select "Compliance Testing"
   - Configure parameters and click "Run workflow"

2. Run the disaster recovery test workflow:
   - Go to Actions tab in GitHub
   - Select "Disaster Recovery Testing"
   - Configure parameters and click "Run workflow"

3. Run the security test workflow:
   - Go to Actions tab in GitHub
   - Select "Security Testing"
   - Configure parameters and click "Run workflow"

### Using Jenkins Pipelines (Legacy)

1. Run the compliance test pipeline:
   ```bash
   cd pipelines/testing/compliance
   ./run-compliance-tests.sh
   ```

2. Run the disaster recovery test pipeline:
   ```bash
   cd pipelines/testing/dr
   ./run-dr-pipeline.sh
   ```

3. View test results:
   ```bash
   ./generate-report.sh
   open reports/latest-report.html
   ```
For detailed usage instructions, please refer to the USAGE.md document.

![testing layout.png](../../docs/testing%20layout.png)

> **Note**: The testing layout diagram needs to be updated to reflect the GitHub Actions workflows implementation. Please refer to `../../docs/testing-layout-description.md` for details on required updates.