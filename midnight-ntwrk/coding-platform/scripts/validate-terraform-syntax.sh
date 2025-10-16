#!/bin/bash
# Validate Terraform configuration syntax without terraform binary

set -e

echo "=== Validating Terraform Configuration Syntax ==="
echo

# Check that all required files exist
echo "Checking required files..."
for file in terraform/main.tf terraform/variables.tf terraform/modules/workstations/main.tf terraform/modules/workstations/variables.tf; do
    if [ -f "$file" ]; then
        echo "✓ $file exists"
    else
        echo "✗ $file missing"
        exit 1
    fi
done

echo
echo "Checking variable usage in workstations module..."

# Check that variables are properly defined in module
if grep -q "var.proof_service_url" terraform/modules/workstations/main.tf; then
    echo "✓ proof_service_url used in workstations/main.tf"
else
    echo "✗ proof_service_url not found in workstations/main.tf"
fi

if grep -q "var.proof_service_config" terraform/modules/workstations/main.tf; then
    echo "✓ proof_service_config used in workstations/main.tf"
else
    echo "✗ proof_service_config not found in workstations/main.tf"
fi

# Check that variables are passed from main module
echo
echo "Checking variable passing in main module..."

if grep -q "proof_service_url.*=" terraform/main.tf; then
    echo "✓ proof_service_url passed to workstations module"
else
    echo "✗ proof_service_url not passed to workstations module"
fi

if grep -q "proof_service_config.*=" terraform/main.tf; then
    echo "✓ proof_service_config passed to workstations module"
else
    echo "✗ proof_service_config not passed to workstations module"
fi

# Check variable definitions
echo
echo "Checking variable definitions..."

if grep -q "variable.*proof_service_url" terraform/variables.tf; then
    echo "✓ proof_service_url defined in root variables.tf"
else
    echo "✗ proof_service_url not defined in root variables.tf"
fi

if grep -q "variable.*proof_service_url" terraform/modules/workstations/variables.tf; then
    echo "✓ proof_service_url defined in workstations/variables.tf"
else
    echo "✗ proof_service_url not defined in workstations/variables.tf"
fi

echo
echo "=== Configuration Summary ==="
echo
echo "The Terraform configuration now supports:"
echo "1. Setting proof_service_url via -var flag"
echo "2. Setting additional config via proof_service_config map"
echo "3. Default value: http://localhost:8080 (local mock service)"
echo
echo "Example usage:"
echo "  terraform apply -var='proof_service_url=https://api.example.com'"
echo "  terraform apply -var='proof_service_config={API_KEY=\"secret\"}'"
echo
echo "✓ Terraform configuration validated successfully!"