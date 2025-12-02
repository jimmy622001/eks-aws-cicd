#!/bin/bash
# run-terraform-compliance.sh
# Script to execute Terraform Compliance tests against Terraform configuration

set -e

# Default values
FEATURE_DIR="terraform-compliance/features"
FEATURE_FILE=""
OUTPUT_DIR="reports"
TERRAFORM_DIR="."
DATE=$(date +%Y-%m-%d)
REPORT_NAME="terraform-compliance-${DATE}"

# Parse command line arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --feature) FEATURE_FILE="$2"; shift 2 ;;
        --terraform-dir) TERRAFORM_DIR="$2"; shift 2 ;;
        --output-dir) OUTPUT_DIR="$2"; shift 2 ;;
        --help)
            echo "Usage: $0 [options]"
            echo "Options:"
            echo "  --feature FEATURE_NAME    Run specific feature test (e.g., eks_security)"
            echo "  --terraform-dir DIR       Directory containing Terraform files (default: .)"
            echo "  --output-dir DIR          Directory for output reports (default: reports)"
            echo "  --help                    Show this help message"
            exit 0
            ;;
        *) echo "Unknown parameter: $1"; exit 1 ;;
    esac
done

# Create output directory if it doesn't exist
mkdir -p ${OUTPUT_DIR}

echo "🔍 Running Terraform Compliance tests..."

# Generate Terraform plan
echo "📝 Generating Terraform plan..."
cd ${TERRAFORM_DIR}
terraform init -input=false
terraform plan -out=tfplan.binary
terraform show -json tfplan.binary > tfplan.json

# Run Terraform Compliance tests
if [ -n "${FEATURE_FILE}" ]; then
    echo "🧪 Running specific feature test: ${FEATURE_FILE}"
    FEATURE_PATH="${FEATURE_DIR}/${FEATURE_FILE}.feature"
    
    # Check if feature file exists
    if [ ! -f "${FEATURE_PATH}" ]; then
        echo "❌ Error: Feature file ${FEATURE_PATH} not found!"
        exit 1
    fi
    
    terraform-compliance -p tfplan.json -f ${FEATURE_PATH} -o ${OUTPUT_DIR}/${REPORT_NAME}-${FEATURE_FILE}.html
else
    echo "🧪 Running all feature tests..."
    terraform-compliance -p tfplan.json -f ${FEATURE_DIR} -o ${OUTPUT_DIR}/${REPORT_NAME}.html
fi

# Check the exit code
if [ $? -eq 0 ]; then
    echo "✅ All compliance tests passed!"
    echo "📊 Report generated: ${OUTPUT_DIR}/${REPORT_NAME}.html"
else
    echo "❌ Some compliance tests failed. Check the report for details."
    echo "📊 Report generated: ${OUTPUT_DIR}/${REPORT_NAME}.html"
    exit 1
fi

# Clean up
rm -f tfplan.binary tfplan.json

echo "✨ Terraform Compliance testing complete!"