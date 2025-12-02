
```bash
#!/bin/bash
# Terraform Compliance Testing Script
# This script runs compliance tests against specific environments
#
# Usage:
#   ./run-terraform-compliance.sh -e <environment> [options]
#
# Environment (-e) specifies which environment to test:
#   dev     - Development environment
#   staging - Staging environment
#   prod    - Production environment
#
# Example usage:
#   ./run-terraform-compliance.sh -e dev          # Test development environment
#   ./run-terraform-compliance.sh -e prod --strict # Test production with strict checks

# Default values
ENVIRONMENT=""
STRICT=false
VERBOSE=false

# Parse command line arguments
while [[ "$#" -gt 0 ]]; do
  case $1 in
    -e|--environment) ENVIRONMENT="$2"; shift ;;
    --strict) STRICT=true ;;
    -v|--verbose) VERBOSE=true ;;
    -h|--help)
      echo "Usage: $0 -e <environment> [options]"
      echo ""
      echo "Options:"
      echo "  -e, --environment ENV   Specify environment to test (dev, staging, prod)"
      echo "  --strict                Enable strict compliance checking"
      echo "  -v, --verbose           Show detailed output"
      echo "  -h, --help              Show this help message"
      exit 0
      ;;
    *) echo "Unknown parameter: $1"; exit 1 ;;
  esac
  shift
done

# Validate environment parameter
if [ -z "$ENVIRONMENT" ]; then
  echo "Error: Environment (-e) is required"
  echo "Usage: $0 -e <environment> [options]"
  exit 1
fi

echo "Running Terraform Compliance tests for $ENVIRONMENT environment"

# Set environment-specific variables
case $ENVIRONMENT in
  dev)
    CONFIG_DIR="environments/development"
    ;;
  staging)
    CONFIG_DIR="environments/staging"
    ;;
  prod)
    CONFIG_DIR="environments/production"
    ;;
  *)
    echo "Error: Unknown environment '$ENVIRONMENT'"
    echo "Valid environments: dev, staging, prod"
    exit 1
    ;;
esac

# Generate Terraform plan for the specified environment
echo "Generating Terraform plan for $ENVIRONMENT environment..."
terraform -chdir=$CONFIG_DIR init
terraform -chdir=$CONFIG_DIR plan -out=tfplan.binary

# Convert plan to JSON
terraform -chdir=$CONFIG_DIR show -json tfplan.binary > tfplan.json

# Run Terraform Compliance against the plan
STRICT_ARG=""
if [ "$STRICT" = true ]; then
  STRICT_ARG="--strict"
fi

VERBOSE_ARG=""
if [ "$VERBOSE" = true ]; then
  VERBOSE_ARG="--verbose"
fi

echo "Running compliance tests against $ENVIRONMENT environment..."
terraform-compliance -p $CONFIG_DIR/tfplan.json -f ../../terraform-compliance/features $STRICT_ARG $VERBOSE_ARG

# Check exit status
if [ $? -eq 0 ]; then
  echo "✅ Compliance tests passed for $ENVIRONMENT environment"
  exit 0
else
  echo "❌ Compliance tests failed for $ENVIRONMENT environment"
  exit 1
fi