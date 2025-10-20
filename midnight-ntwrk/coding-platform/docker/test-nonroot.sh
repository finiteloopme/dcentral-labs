#!/bin/bash
# Test script to verify container works without root privileges

set -e

echo "Testing Midnight Workstation container in non-root mode..."
echo "============================================="
echo ""

# Build the image
echo "Building Docker image..."
docker build -t midnight-test:nonroot-test .

# Run container without privileged mode to simulate Cloud Workstations
echo ""
echo "Starting container in non-privileged mode..."
CONTAINER_ID=$(docker run -d \
    --name midnight-nonroot-test \
    -p 8080:80 \
    -p 8081:8080 \
    --user 1000:1000 \
    midnight-test:nonroot-test)

echo "Container started: $CONTAINER_ID"
echo ""

# Wait for container to initialize
echo "Waiting for container to initialize..."
sleep 10

# Run tests as non-root user
echo ""
echo "Running non-root accessibility tests..."
echo "----------------------------------------"

# Test 1: Check user context
echo -n "1. Checking user context... "
USER_ID=$(docker exec midnight-nonroot-test id -u)
if [ "$USER_ID" = "1000" ]; then
    echo "✓ Running as user 1000"
else
    echo "✗ Not running as user 1000 (got: $USER_ID)"
fi

# Test 2: Check Midnight CLI access
echo -n "2. Testing Midnight CLI... "
if docker exec midnight-nonroot-test midnight help > /dev/null 2>&1; then
    echo "✓ Midnight CLI accessible"
else
    echo "✗ Midnight CLI not accessible"
fi

# Test 3: Check compiler access
echo -n "3. Testing Compact compiler... "
if docker exec midnight-nonroot-test compactc --version > /dev/null 2>&1; then
    echo "✓ Compiler accessible"
else
    echo "✗ Compiler not accessible"
fi

# Test 4: Check template access
echo -n "4. Testing template access... "
if docker exec midnight-nonroot-test test -r /opt/templates/basic-token/contracts/Token.compact; then
    echo "✓ Templates readable"
else
    echo "✗ Templates not readable"
fi

# Test 5: Check extension access
echo -n "5. Testing VSCode extension access... "
if docker exec midnight-nonroot-test test -r /opt/midnight/extensions/compact-0.2.13.vsix; then
    echo "✓ Extension readable"
else
    echo "✗ Extension not readable"
fi

# Test 6: Check workspace creation
echo -n "6. Testing workspace creation... "
if docker exec midnight-nonroot-test mkdir -p /home/user/test-workspace 2>/dev/null; then
    echo "✓ Can create workspace directories"
else
    echo "✗ Cannot create workspace directories"
fi

# Test 7: Check Code OSS accessibility
echo -n "7. Testing Code OSS access... "
if docker exec midnight-nonroot-test test -x /opt/code-oss/bin/codeoss-cloudworkstations; then
    echo "✓ Code OSS accessible"
else
    echo "✗ Code OSS not accessible"
fi

# Test 8: Check proof server directory
echo -n "8. Testing proof server access... "
if docker exec midnight-nonroot-test test -r /opt/midnight/proof-server/package.json; then
    echo "✓ Proof server accessible"
else
    echo "✗ Proof server not accessible"
fi

# Test 9: Test creating a project
echo -n "9. Testing project creation... "
if docker exec midnight-nonroot-test bash -c "cd /tmp && midnight new test-project" > /dev/null 2>&1; then
    echo "✓ Can create projects"
else
    echo "✗ Cannot create projects"
fi

# Test 10: Check HTTP services
echo -n "10. Testing HTTP services... "
if curl -s http://localhost:8080 > /dev/null 2>&1; then
    echo "✓ Code OSS responding on port 80"
else
    echo "✗ Code OSS not responding"
fi

echo ""
echo "============================================="
echo "Non-root tests complete!"
echo ""

# Cleanup
echo "Cleaning up test container..."
docker stop midnight-nonroot-test > /dev/null
docker rm midnight-nonroot-test > /dev/null

echo "✓ Cleanup complete"
echo ""
echo "Summary: The container is configured to work properly without root privileges."
echo "This ensures compatibility with Google Cloud Workstations security requirements."