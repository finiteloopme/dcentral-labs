#!/bin/bash
# Test what's in the base image

echo "Testing base Cloud Workstations image..."
echo ""

# Run a simple command in the base image to check for Code OSS
docker run --rm \
    us-central1-docker.pkg.dev/cloud-workstations-images/predefined/code-oss \
    ls -la /opt/code-oss/bin/ 2>/dev/null || echo "Failed to list /opt/code-oss/bin/"

echo ""
echo "Checking for code-oss executables..."
docker run --rm \
    us-central1-docker.pkg.dev/cloud-workstations-images/predefined/code-oss \
    find /opt -type f -name "*code*" -executable 2>/dev/null | head -10