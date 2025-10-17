#!/bin/bash
# Script to validate Terraform configuration locally
# This helps debug Cloud Build validation failures

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Terraform Validation Script${NC}"
echo "=============================="
echo

# Check if terraform is installed
if ! command -v terraform &> /dev/null; then
    echo -e "${RED}Error: Terraform is not installed${NC}"
    echo "Please install Terraform first: https://www.terraform.io/downloads"
    exit 1
fi

cd "$(dirname "$0")/../terraform"

echo -e "${YELLOW}Step 1: Initializing Terraform (without backend)...${NC}"
terraform init -backend=false || {
    echo -e "${RED}Initialization failed!${NC}"
    exit 1
}
echo -e "${GREEN}✓ Initialization successful${NC}"
echo

echo -e "${YELLOW}Step 2: Running terraform validate...${NC}"
if terraform validate; then
    echo -e "${GREEN}✓ Validation passed${NC}"
else
    echo -e "${RED}✗ Validation failed${NC}"
    echo "Please fix the validation errors above"
    exit 1
fi
echo

echo -e "${YELLOW}Step 3: Checking formatting...${NC}"
if terraform fmt -check=true -diff; then
    echo -e "${GREEN}✓ Format check passed${NC}"
else
    echo -e "${RED}✗ Format check failed${NC}"
    echo
    echo "To fix formatting issues, run:"
    echo "  cd terraform && terraform fmt"
    echo
    echo "Files that need formatting:"
    terraform fmt -check=false -list=true
    exit 1
fi
echo

echo -e "${YELLOW}Step 4: Checking for deprecated features...${NC}"
# Check for deprecated syntax
deprecated_found=false

# Check for interpolation-only expressions (deprecated in 0.12+)
if grep -r '\${var\.' --include="*.tf" . 2>/dev/null | grep -v '#'; then
    echo -e "${YELLOW}Warning: Found interpolation-only expressions (consider removing \${ } wrapper)${NC}"
    deprecated_found=true
fi

# Check for count with boolean (deprecated pattern)
if grep -r 'count.*=.*?.*1.*:.*0' --include="*.tf" . 2>/dev/null; then
    echo -e "${YELLOW}Warning: Found conditional count pattern (consider using for_each or count with length())${NC}"
    deprecated_found=true
fi

if [ "$deprecated_found" = false ]; then
    echo -e "${GREEN}✓ No deprecated patterns found${NC}"
fi
echo

echo -e "${GREEN}=============================="
echo -e "All validation checks passed!"
echo -e "==============================${NC}"
echo
echo "Your Terraform configuration is ready for Cloud Build."