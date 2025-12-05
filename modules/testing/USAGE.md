# AWS Infrastructure Testing Module - Usage Guide

This document provides detailed instructions for using the testing module, including running the testing pipelines, working with the attached playbooks and runbooks, and reporting procedures.

## Prerequisites

- AWS CLI configured with appropriate permissions
- Terraform (for infrastructure deployment)
- Python 3.8+ (for test scripts)
- Access to AWS account with permissions to create test resources
- Required IAM roles and policies configured

## Running the Testing Pipelines

### Testing with GitHub Actions (Recommended)

We now support GitHub Actions workflows for all testing operations:

#### Running Compliance Tests with GitHub Actions

1. Navigate to the Actions tab in GitHub
2. Select the "Compliance Testing" workflow
3. Click "Run workflow"
4. Configure the following parameters:
   - Environment (dev/prod/dr)
   - Generate report (true/false)
5. Click "Run workflow"
6. Once complete, download the compliance reports from the workflow artifacts

#### Running DR Tests with GitHub Actions

1. Navigate to the Actions tab in GitHub
2. Select the "Disaster Recovery Testing" workflow
3. Click "Run workflow"
4. Configure test parameters including:
   - Environment
   - Primary and DR regions
   - Network disruption settings
   - Target RPO and RTO values
5. Click "Run workflow"
6. Once complete, download the DR test report from the workflow artifacts

#### Running Security Tests with GitHub Actions

1. Navigate to the Actions tab in GitHub
2. Select the "Security Testing" workflow
3. Click "Run workflow"
4. Configure parameters:
   - Environment to test
   - Scan type (full/quick/targeted)
   - Report generation
   - Failure threshold
5. Click "Run workflow"
6. Once complete, download the security reports from the workflow artifacts

### Using Jenkins Pipelines (Legacy)

#### Infrastructure Compliance Testing Pipeline

This pipeline validates your AWS infrastructure against the AWS Well-Architected Framework pillars.

1. Execute the compliance testing pipeline:

   ```bash
   cd pipelines/testing/compliance
   ./run-compliance-tests.sh
   ```

   For specific pillar testing:
   ```bash
   # Test security pillar only
   ./run-compliance-tests.sh --pillar security

   # Test reliability pillar only
   ./run-compliance-tests.sh --pillar reliability
   ```

2. Generate and view the compliance report:
   ```bash
   ./generate-report.sh
   open reports/compliance-$(date +%Y-%m-%d).html
   ```

### Terraform Compliance Testing

This pipeline validates your Terraform configuration files against compliance policies using BDD-style tests.

1. Execute the Terraform Compliance tests:

   ```bash
   cd pipelines/testing
   ./run-terraform-compliance.sh
   ```

   For testing specific compliance features:
   ```bash
   # Test EKS security compliance only
   ./run-terraform-compliance.sh --feature eks_security

   # Test S3 security compliance only
   ./run-terraform-compliance.sh --feature s3_security
   ```

2. View compliance test results:
   ```bash
   open reports/terraform-compliance-$(date +%Y-%m-%d).html
   ```

3. For more information about Terraform Compliance tests, refer to:
   ```bash
   cat terraform-compliance/README.md
   ```

### Disaster Recovery Testing Pipeline

This pipeline specifically tests DR capabilities and measures recovery metrics.

1. Execute the DR testing pipeline:
   ```bash
   cd pipelines/testing/dr
   ./run-dr-pipeline.sh
   ```

   For testing specific DR scenarios:
   ```bash
   # Test AZ failover
   ./run-dr-pipeline.sh --scenario az-failover

   # Test database recovery
   ./run-dr-pipeline.sh --scenario db-recovery

   # Test region failover
   ./run-dr-pipeline.sh --scenario region-failover
   ```

2. View DR test results:
   ```bash
   ./show-dr-metrics.sh --last-run
   ```

## Using the Runbooks

The module includes three essential runbooks to support your testing activities:

### 1. Incident Response Runbook (incident-response.md)

This runbook provides a structured approach to managing incidents during testing.

**When to use:**
- When an unplanned incident occurs during testing
- To classify incident severity
- To follow proper escalation procedures
- For documenting post-incident analysis

**Key sections:**
- Incident classification matrix
- Escalation paths and contact information
- Response procedures by incident type
- Post-incident review templates

### 2. Test Environment Setup (test-environment-setup.md)

This runbook guides you through setting up isolated test environments.

**When to use:**
- Before running any DR or compliance tests
- When preparing a new test environment
- For refreshing test data

**Key steps:**
1. Provision the test infrastructure:
   ```bash
   cd modules/testing
   terraform init
   terraform apply -var-file=test-environment.tfvars
   ```

2. Validate the environment:
   ```bash
   ./validate-test-env.sh
   ```

3. Seed test data:
   ```bash
   ./seed-test-data.sh
   ```

### 3. Test Execution Procedures (test-execution.md)

This runbook provides detailed steps for executing different test scenarios.

**When to use:**
- During scheduled DR testing
- For ad-hoc DR validation
- When measuring recovery metrics

**Key test types:**
1. Application recovery testing:
   ```bash
   ./run-app-recovery-test.sh
   ```

2. Database failover testing:
   ```bash
   ./run-db-failover-test.sh
   ```

3. Multi-region failover:
   ```bash
   ./run-region-failover-test.sh
   ```

## Test Data Management

### Backup Test Data

Before running tests that might modify data:
```bash
./backup-test-data.sh
```

### Restore Test Data

To return to a known good state:
```bash
./restore-test-data.sh --snapshot latest
```

## Reporting

### Automated Reports

Reports are automatically generated after pipeline execution:
- Compliance reports: `reports/compliance-*.html`
- DR test reports: `reports/dr-test-*.html`
- Performance metrics: `reports/metrics-*.json`

### Manual Report Generation

1. Compliance test reports:
   ```bash
   ./generate-compliance-report.sh --format [html|pdf|json]
   ```

2. DR test performance reports:
   ```bash
   ./generate-dr-report.sh --last-run
   ```

3. Historical metrics dashboard:
   ```bash
   ./open-metrics-dashboard.sh
   ```

## Integration with CI/CD

### GitHub Actions Integration (Recommended)

The testing workflows are already integrated with CI/CD:

- **Automatic Triggers**: 
  - Compliance tests run automatically when infrastructure code changes
  - DR tests run automatically when DR-related configurations change
  - Security tests run automatically on code changes

- **PR Checks**: 
  - Tests can be configured as required checks before merging PRs
  - Each workflow generates artifacts with detailed reports

- **Environment Deployment Validation**: 
  - Use these workflows to validate environment changes before deployment
  - Incorporate test results into deployment decisions

- **Scheduled Testing**:
  - Set up scheduled runs of these workflows to ensure ongoing compliance and security
  - Example schedule configuration in workflow files:
    ```yaml
    on:
      schedule:
        - cron: '0 0 * * 0'  # Run every Sunday at midnight
    ```

### Other CI/CD Systems

For other CI/CD systems like GitLab CI:

```yaml
# Example GitLab CI configuration
dr_testing:
  stage: test
  script:
    - cd pipelines/testing/dr
    - ./run-dr-pipeline.sh --ci-mode
  artifacts:
    paths:
      - reports/
```

## Troubleshooting

If you encounter issues while running pipelines or tests:

1. Check the logs in `logs/` directory
2. Verify AWS credentials and permissions
3. Ensure all prerequisites are met
4. Consult the Incident Response Runbook for guidance

## Support

For assistance with the testing module, contact:
- AWS Infrastructure Team
- Platform Engineering Team
- Cloud Operations Team