# Terraform Compliance Testing

This directory contains BDD-style compliance tests for our Terraform code using terraform-compliance.

## Requirements

- terraform-compliance (Install with `pip install terraform-compliance`)
- Terraform 0.12+

## Running Compliance Tests

To run compliance tests against your Terraform plan:

```bash
# Generate a plan file
terraform plan -out=tfplan.out

# Convert the plan to JSON
terraform show -json tfplan.out > tfplan.json

# Run terraform-compliance against the plan
terraform-compliance -p tfplan.json -f terraform-compliance/features/

```

## Features

The `features` directory contains BDD-style compliance tests organized by resource type:

- `eks_security.feature`: Compliance rules for EKS clusters
- `s3_security.feature`: Compliance rules for S3 buckets

## Integration with CI/CD

These compliance tests can be integrated into your CI/CD pipeline by adding the following steps to your Jenkinsfile:

```groovy
stage('Compliance Testing') {
  steps {
    sh 'terraform plan -out=tfplan.out'
    sh 'terraform show -json tfplan.out > tfplan.json'
    sh 'terraform-compliance -p tfplan.json -f terraform-compliance/features/'
  }
}
```

## Writing New Compliance Rules

To add new compliance rules:

1. Create a new `.feature` file in the `features` directory or add to an existing one
2. Follow the BDD syntax: Given, When, Then
3. Use the terraform-compliance language for expressing resource compliance requirements
4. Test your rules locally before committing

For more information on writing compliance rules, see the [terraform-compliance documentation](https://terraform-compliance.com/pages/bdd-references/).