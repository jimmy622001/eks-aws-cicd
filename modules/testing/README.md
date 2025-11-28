# Architecture Testing Framework

This module provides comprehensive testing frameworks for all five pillars of the AWS Well-Architected Framework:

1. Security
2. Reliability
3. Performance Efficiency
4. Cost Optimization
5. Operational Excellence

## Overview

The testing framework is designed to validate that your infrastructure meets best practices and requirements across all architecture pillars. Each module focuses on specific aspects of the architecture and can be run independently or as part of a comprehensive test suite.

## Modules

### Security Testing
- Evaluates security posture using AWS Security Hub
- Implements GuardDuty for threat detection
- Validates IAM permissions and access control
- Checks for S3 bucket security compliance
- Validates network security configurations
- Performs database security assessments
- Simulated penetration testing (dev environment only)

### Reliability (DR) Testing
- Tests failover mechanisms with AWS Fault Injection Simulator
- Validates multi-region replication
- Measures and verifies Recovery Time Objective (RTO)
- Measures and verifies Recovery Point Objective (RPO)
- Network connectivity disruption testing (dev environment only)
- Data integrity validation during recovery

### Performance Efficiency Testing
- EKS cluster autoscaling tests
- Load testing for system capacity
- Resource utilization optimization checks
- Performance under load testing
- Scaling pattern validation
- Analysis of performance metrics against targets

### Cost Optimization Testing
- Idle resource detection
- Right-sizing recommendations
- Reserved instance coverage analysis
- Spot instance utilization opportunities
- Budget monitoring and anomaly detection
- Resource tagging compliance

### Operational Excellence Testing
- CloudWatch dashboards and alarms evaluation
- CI/CD pipeline validation
- CloudTrail log analysis
- Documentation and runbook validation
- Incident response verification
- Alarm configuration verification

## Usage

You can apply these testing modules to both dev and prod environments. The modules are configured to be non-invasive and won't affect the operation of your core infrastructure.

### Manual Execution

```bash
# Apply a specific testing module
cd environments/dev
terraform apply -target=module.security_testing

# Run all tests
terraform apply

# Remove testing resources when done
terraform destroy -target=module.security_testing
```

### Automated Execution via Jenkins

A Jenkins pipeline has been created that can run these tests on a schedule:

1. The pipeline is defined in `jenkins/pipelines/architecture-testing-pipeline.groovy`
2. Job configuration is in `jenkins/jobs/architecture-testing-job.yaml`
3. Tests run weekly by default but can be triggered manually
4. The pipeline applies the test resources, executes the tests, captures results, and then destroys the testing resources

## Environment-Specific Configurations

- **Dev Environment**: More aggressive testing, including simulated penetration testing and network disruption
- **Prod Environment**: More conservative testing to avoid any impact on production workloads, with stricter RTO/RPO requirements

## Test Results

Test results are sent to:
1. Email notifications
2. CloudWatch dashboards
3. SNS topics that can integrate with other notification systems
4. Lambda functions store results in S3 for historical analysis