#!/bin/bash
# Inspect the base image to understand its structure

echo "Inspecting Cloud Workstations base image..."
echo "==========================================="
echo ""

# Check startup scripts
echo "Startup scripts in base image:"
docker run --rm --entrypoint /bin/bash \
    us-central1-docker.pkg.dev/cloud-workstations-images/predefined/code-oss \
    -c "ls -la /etc/workstation-startup.d/ 2>/dev/null | grep -E '\.sh$'"

echo ""
echo "Looking for Code OSS startup script:"
docker run --rm --entrypoint /bin/bash \
    us-central1-docker.pkg.dev/cloud-workstations-images/predefined/code-oss \
    -c "grep -l 'code-oss\|codeoss' /etc/workstation-startup.d/*.sh 2>/dev/null"

echo ""
echo "Content of Code OSS startup script (if found):"
docker run --rm --entrypoint /bin/bash \
    us-central1-docker.pkg.dev/cloud-workstations-images/predefined/code-oss \
    -c "cat /etc/workstation-startup.d/*code*.sh 2>/dev/null || echo 'No code startup script found'"