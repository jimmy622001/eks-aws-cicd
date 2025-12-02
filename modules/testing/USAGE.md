You're right, I should make sure the USAGE.md file retains clear instructions for running the pipelines. Let me revise the USAGE.md file to ensure it includes detailed instructions for running both the infrastructure compliance testing pipeline and the DR testing pipeline, along with how to use the attached runbooks (incident-response.md, test-environment-setup.md, and test-execution.md).

Here's the revised USAGE.md with clearer pipeline instructions:

USAGE.md
# AWS Infrastructure Testing Module - Usage Guide

This document provides detailed instructions for using the testing module, including running the testing pipelines, working with the attached playbooks and runbooks, and reporting procedures.

## Prerequisites

- AWS CLI configured with appropriate permissions
- Terraform (for infrastructure deployment)
- Python 3.8+ (for test scripts)
- Access to AWS account with permissions to create test resources
- Required IAM roles and policies configured

## Running the Testing Pipelines

### Infrastructure Compliance Testing Pipeline

This pipeline validates your AWS infrastructure against the AWS Well-Architected Framework pillars.

1. Execute the compliance testing pipeline:

   ```bash
   cd pipelines/testing/compliance
   ./run-compliance-tests.sh
For specific pillar testing:
# Test security pillar only
./run-compliance-tests.sh --pillar security

# Test reliability pillar only
./run-compliance-tests.sh --pillar reliability
Generate and view the compliance report:
./generate-report.sh
open reports/compliance-$(date +%Y-%m-%d).html
Disaster Recovery Testing Pipeline
This pipeline specifically tests DR capabilities and measures recovery metrics.

Execute the DR testing pipeline:
cd pipelines/testing/dr
./run-dr-pipeline.sh
For testing specific DR scenarios:
# Test AZ failover
./run-dr-pipeline.sh --scenario az-failover

# Test database recovery
./run-dr-pipeline.sh --scenario db-recovery

# Test region failover
./run-dr-pipeline.sh --scenario region-failover
View DR test results:
./show-dr-metrics.sh --last-run
Using the Runbooks
The module includes three essential runbooks to support your testing activities:

1. Incident Response Runbook (incident-response.md)
   This runbook provides a structured approach to managing incidents during testing.

When to use:

When an unplanned incident occurs during testing
To classify incident severity
To follow proper escalation procedures
For documenting post-incident analysis
Key sections:

Incident classification matrix
Escalation paths and contact information
Response procedures by incident type
Post-incident review templates
2. Test Environment Setup (test-environment-setup.md)
   This runbook guides you through setting up isolated test environments.

When to use:

Before running any DR or compliance tests
When preparing a new test environment
For refreshing test data
Key steps:

Provision the test infrastructure:
cd modules/testing
terraform init
terraform apply -var-file=test-environment.tfvars
Validate the environment:
./validate-test-env.sh
Seed test data:
./seed-test-data.sh
3. Test Execution Procedures (test-execution.md)
   This runbook provides detailed steps for executing different test scenarios.

When to use:

During scheduled DR testing
For ad-hoc DR validation
When measuring recovery metrics
Key test types:

Application recovery testing:
./run-app-recovery-test.sh
Database failover testing:
./run-db-failover-test.sh
Multi-region failover:
./run-region-failover-test.sh
Test Data Management
Backup Test Data
Before running tests that might modify data:

./backup-test-data.sh
Restore Test Data
To return to a known good state:

./restore-test-data.sh --snapshot latest
Reporting
Automated Reports
Reports are automatically generated after pipeline execution:

Compliance reports: reports/compliance-*.html
DR test reports: reports/dr-test-*.html
Performance metrics: reports/metrics-*.json
Manual Report Generation
Compliance test reports:
./generate-compliance-report.sh --format [html|pdf|json]
DR test performance reports:
./generate-dr-report.sh --last-run
Historical metrics dashboard:
./open-metrics-dashboard.sh
Integration with CI/CD
The testing pipelines can be integrated with your CI/CD workflow:

# Example GitLab CI configuration
dr_testing:
stage: test
script:
- cd pipelines/testing/dr
- ./run-dr-pipeline.sh --ci-mode
artifacts:
paths:
- reports/
Troubleshooting
If you encounter issues while running pipelines or tests:

Check the logs in logs/ directory
Verify AWS credentials and permissions
Ensure all prerequisites are met
Consult the Incident Response Runbook for guidance
Support
For assistance with the testing module, contact:

AWS Infrastructure Team
Platform Engineering Team
Cloud Operations Team

