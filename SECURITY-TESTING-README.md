# Security Testing Branch

This branch contains security testing pipelines that can be applied to various AWS infrastructure projects. Changes to this branch will automatically trigger the security testing pipeline in Jenkins.

## Purpose

The security-testing branch is dedicated to:

1. Maintaining security testing Jenkinsfiles and resources
2. Allowing security engineers to update testing procedures independently
3. Triggering automated security scans against defined infrastructure

## How to Use

When you push changes to this branch, Jenkins will automatically trigger the security testing pipeline. This pipeline:

- Runs against the infrastructure defined in the target environment
- Performs GuardDuty, Config compliance, IAM, and VPC flow log analysis
- Generates security reports

## Jenkins Job Configuration

The Jenkins job is configured to:
- Run daily at midnight automatically
- Trigger immediately when changes are pushed to this branch
- Use parameters for configuring which tests to run and against which environment

## Parameters

- `ENVIRONMENT`: Which environment to run tests against (dev, prod)
- `RUN_GUARDDUTY_TESTS`: Whether to run GuardDuty security tests
- `RUN_CONFIG_TESTS`: Whether to run AWS Config compliance tests
- `RUN_IAM_TESTS`: Whether to run IAM security tests

## Testing Infrastructure

The security tests are implemented as AWS Lambda functions that are deployed as part of the terraform module. These test resources are automatically cleaned up after the pipeline completes.