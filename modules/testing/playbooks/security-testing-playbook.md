# AWS Security Testing Playbook

## Overview

This playbook provides structured procedures for validating the security controls and configurations of AWS infrastructure, particularly under disaster scenarios.

## Test Categories

### 1. Infrastructure-as-Code Compliance Tests

#### 1.1. Terraform Compliance Testing

**Objective**: Validate Terraform configurations against security policies and compliance requirements using BDD-style tests.

**Procedure**:
1. Run Terraform Compliance tests against Terraform plan
   ```bash
   cd pipelines/testing
   ./run-terraform-compliance.sh
   ```
2. Review non-compliant resources and configurations
3. Document findings and remediation steps
4. Validate fixes with re-testing

**Success Criteria**:
- All Terraform configurations pass compliance tests
- No critical security misconfigurations in infrastructure code
- Compliance with organizational security policies

#### 1.2. Static Code Analysis

**Objective**: Identify security issues in infrastructure code using static analysis tools.

**Procedure**:
1. Run Checkov against Terraform code
   ```bash
   checkov -d . --framework terraform
   ```
2. Run tfsec for additional security findings
   ```bash
   tfsec .
   ```
3. Document and remediate identified issues

**Success Criteria**:
- No high or critical security findings in infrastructure code
- Compliance with security best practices
- Properly configured security controls in all infrastructure components

### 2. IAM Security Tests

#### 1.1. IAM Role and Policy Validation

**Objective**: Verify that IAM roles and policies follow least privilege principles.

**Procedure**:
1. Run InSpec controls from `inspec/profiles/security/controls/iam.rb`
2. Review permission boundaries implementation
3. Validate service role permissions against best practices
4. Document any excessive permissions
5. Recommend remediation steps

**Success Criteria**:
- No roles with `*:*` permissions
- Service roles limited to required services only
- No security findings of HIGH or CRITICAL severity

#### 1.2. Credential Rotation and Management

**Objective**: Verify credential management practices are secure.

**Procedure**:
1. Execute InSpec controls for access key age
2. Validate MFA enforcement on privileged accounts
3. Check for unused credentials using AWS Config rules
4. Document findings and remediation

**Success Criteria**:
- Access keys rotated within 90 days
- MFA enforced on all privileged accounts
- No unused credentials older than 45 days

### 2. Network Security Tests

#### 2.1. Security Group Configuration

**Objective**: Verify security groups follow least access principles.

**Procedure**:
1. Run InSpec controls from `inspec/profiles/security/controls/security_groups.rb`
2. Identify any overly permissive rules
3. Validate against network segmentation requirements
4. Document findings

**Success Criteria**:
- No security groups with 0.0.0.0/0 ingress except to public endpoints
- No unnecessary ports exposed
- Security group rules documented and justified

#### 2.2. VPC Flow Log Effectiveness

**Objective**: Verify VPC flow logs capture required traffic data.

**Procedure**:
1. Validate flow log configuration using InSpec controls
2. Generate test traffic between VPCs
3. Validate traffic appears in logs
4. Check log retention settings
5. Document findings

**Success Criteria**:
- All VPCs have flow logging enabled
- Logs capture required traffic metadata
- Log retention periods meet compliance requirements

### 3. Data Security Tests

#### 3.1. Encryption Configuration

**Objective**: Verify data encryption at rest and in transit.

**Procedure**:
1. Run InSpec controls for encryption settings
2. Validate KMS key management procedures
3. Test S3 bucket encryption settings
4. Verify RDS/DynamoDB encryption configuration
5. Document findings

**Success Criteria**:
- All sensitive data encrypted at rest
- TLS enforced for all service communications
- KMS keys rotated according to policy

#### 3.2. Secrets Management

**Objective**: Verify secure secrets management.

**Procedure**:
1. Validate AWS Secrets Manager or Parameter Store usage
2. Check for hardcoded secrets in configuration files
3. Verify rotation policies for managed secrets
4. Document findings

**Success Criteria**:
- No hardcoded secrets in code or configuration
- Secrets automatically rotated according to policy
- Access to secrets properly restricted

### 4. Disaster Recovery Security Tests

#### 4.1. Security Posture During Failover

**Objective**: Verify security controls remain effective during DR scenarios.

**Procedure**:
1. Execute DR failover test
2. Run InSpec security controls against DR environment
3. Compare security posture against primary environment
4. Validate security monitoring continuity
5. Document findings

**Success Criteria**:
- All security controls function in DR environment
- No reduction in security posture during failover
- Security monitoring continues uninterrupted

## Execution Guidelines

1. Obtain proper authorization before security testing
2. Start with Infrastructure-as-Code testing before deploying resources
3. Document all findings with evidence
4. Classify findings by severity
5. Develop remediation plan for identified issues
6. Retest after remediation

## Reporting

Complete the security test report template in `test-reports/templates/security-test-report.md` for each test execution.