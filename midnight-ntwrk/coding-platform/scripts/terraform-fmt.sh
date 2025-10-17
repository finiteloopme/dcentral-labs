#!/bin/bash
# Script to fix Terraform formatting issues

cd "$(dirname "$0")/../terraform"

echo "Fixing Terraform formatting..."

# Process all .tf files
for file in $(find . -name "*.tf" -type f); do
    echo "Processing: $file"
    
    # Create a temporary file
    temp_file="${file}.tmp"
    
    # Read the file and fix formatting (preserve all lines including empty ones at end)
    # Use -r to preserve backslashes, and process empty lines
    while IFS= read -r line || [ -n "$line" ]; do
        # Fix multiple spaces around = (but not in comments)
        if [[ ! "$line" =~ ^[[:space:]]*# ]]; then
            # Replace multiple spaces around = with single space
            # But preserve indentation at the beginning of lines
            line=$(echo "$line" | sed -E 's/([^[:space:]])  += +/\1 = /g; s/([^[:space:]]) += +/\1 = /g; s/([^[:space:]])  +=([^[:space:]])/\1 = \2/g')
        fi
        echo "$line"
    done < "$file" > "$temp_file"
    
    # Replace original file with formatted version
    mv "$temp_file" "$file"
done

echo "Formatting complete!"

# If terraform is available, use it for final formatting
if command -v terraform &> /dev/null; then
    echo "Running terraform fmt for final formatting..."
    terraform fmt -recursive .
    echo "Terraform fmt complete!"
else
    echo "Note: Terraform is not installed. Install it and run 'terraform fmt' for complete formatting."
fi