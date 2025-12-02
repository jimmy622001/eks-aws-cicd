# EKS AWS CI/CD Testing Overview

This document provides an overview of the testing strategy implemented in our EKS AWS CI/CD infrastructure. It outlines the different types of tests, their intrusiveness levels, and recommendations for which environments they should be executed in.

## Testing Types and Intrusiveness

| Test Type | Intrusiveness | Dev Environment | Production Environment | Test/Replica Environment |
|-----------|---------------|----------------|------------------------|--------------------------|
| Security Testing | Low (Non-intrusive) | ✅ Recommended | ✅ Safe to run | ✅ Recommended |
| Disaster Recovery (DR) Testing | High (Intrusive) | ✅ Recommended | ⚠️ Only with caution | ✅ Ideal environment |

## 1. Security Testing

### Overview
Security testing focuses on validating the security posture of our infrastructure without making disruptive changes to running systems.

### What It Tests
- Infrastructure-as-Code (Terraform) compliance checks
- IAM roles and policies validation
- Network security configuration validation
- Encryption and secrets management validation
- Kubernetes security best practices
- Container image vulnerabilities
- Compliance with organizational security policies

### Intrusiveness Level: Low (Non-intrusive)
These tests are designed to be observational and do not:
- Modify running infrastructure
- Interrupt service availability
- Create or delete resources
- Modify security configurations

### Recommended Environments
- **Dev Environment**: Safe to run for early detection of issues
- **Production Environment**: Safe to run for validation of actual security posture
- **Test/Replica Environment**: Safe to run for comprehensive testing

### Implementation
Security testing is implemented in `pipelines/testing/security-Jenkinsfile` and uses various security scanning tools to identify potential vulnerabilities without making changes to the infrastructure.

## 2. Disaster Recovery (DR) Testing

### Overview
DR testing validates the system's ability to recover from failures and ensures business continuity objectives can be met.

### What It Tests
- Network disruption scenarios
- Availability zone failures
- Node failure and recovery
- Cluster failover mechanisms
- Database failover and recovery
- RTO (Recovery Time Objective) validation
- RPO (Recovery Point Objective) validation
- Service resilience under stress conditions

### Intrusiveness Level: High (Intrusive)
These tests are designed to simulate real failures and may:
- Deliberately interrupt network connectivity
- Terminate instances or services
- Force failovers
- Create resource constraints
- Simulate AWS service outages using Fault Injection Simulator (FIS)

### Recommended Environments
- **Dev Environment**: Good for initial validation without business impact
- **Production Environment**: Only during scheduled maintenance windows with proper approvals and safeguards
- **Test/Replica Environment**: Ideal - provides high-fidelity testing without production impact

### Implementation
DR testing is implemented in `pipelines/testing/dr-Jenkinsfile` and leverages AWS FIS and custom scripts to simulate failures and validate recovery.

## Setting Up a Test/Replica Environment

For thorough DR testing, we recommend setting up a dedicated test environment that replicates production:

1. Follow the procedures in `test-environment-setup.md` to create a replica of the production environment
2. Ensure the test environment has:
   - Same Kubernetes version and configurations
   - Similar (though potentially scaled-down) node groups
   - Identical networking setup
   - Representative workloads for realistic testing

## Test Execution Guidelines

### For Security Testing
1. Run regularly as part of CI/CD pipeline in all environments
2. Schedule comprehensive scans weekly or after major infrastructure changes
3. Review findings with the security team before deploying to production
4. Document and track remediation of identified issues

### For DR Testing
1. Always begin with testing in the dev environment
2. Progress to the test/replica environment for more thorough validation
3. Document clear objectives, success criteria, and roll-back procedures
4. Ensure monitoring is in place to capture test results and metrics
5. Implement timeouts and automatic recovery for all tests
6. Only proceed with production DR testing after:
   - Successful validation in dev and test environments
   - Obtaining proper approvals
   - Scheduling during maintenance windows
   - Notifying all stakeholders
   - Having a response team on standby

## Continuous Improvement

The testing strategy should evolve over time:

1. Regularly review and update test scenarios based on:
   - New threat intelligence
   - Changes to infrastructure
   - Lessons learned from incidents
   - Industry best practices

2. Enhance test coverage as the system matures:
   - Expand security testing to cover new components
   - Add more complex failure scenarios to DR testing
   - Incorporate chaos engineering principles

3. Track and improve key metrics:
   - Test coverage percentage
   - Mean time to detect (MTTD)
   - Mean time to recover (MTTR)
   - False positive rates