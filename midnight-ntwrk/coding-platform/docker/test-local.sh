#!/bin/bash
# Test that the container works locally with proper user creation

echo "Testing local container startup..."
echo "=================================="
echo ""

# Build the image
echo "Building image..."
if ! docker build -t midnight-local-test:latest . ; then
    echo "✗ Build failed"
    exit 1
fi

echo ""
echo "Starting container..."
CONTAINER_ID=$(docker run -d \
    --name midnight-local-test \
    -p 8080:80 \
    -p 8081:8080 \
    midnight-local-test:latest)

echo "Container started: ${CONTAINER_ID:0:12}"
echo ""

# Wait for startup
echo "Waiting for startup scripts to complete (20 seconds)..."
sleep 20

# Check if user was created
echo ""
echo "Checking user creation..."
echo "--------------------------"
echo -n "1. User 'user' exists: "
if docker exec midnight-local-test id user >/dev/null 2>&1; then
    echo "✓ Yes"
    docker exec midnight-local-test id user
else
    echo "✗ No"
fi

# Check startup script execution
echo ""
echo -n "2. Startup scripts ran: "
if docker exec midnight-local-test ls /etc/workstation-startup.d/ | grep -q "100_"; then
    echo "✓ Yes"
else
    echo "✗ No"
fi

# Check Code OSS
echo ""
echo -n "3. Code OSS process: "
if docker exec midnight-local-test pgrep -f "codeoss-cloudworkstations" >/dev/null 2>&1; then
    echo "✓ Running"
else
    echo "✗ Not running"
fi

# Check port 80
echo ""
echo -n "4. Port 80 listening: "
if docker exec midnight-local-test netstat -tuln 2>/dev/null | grep -q ":80 "; then
    echo "✓ Yes"
else
    echo "✗ No (might need netstat installed)"
fi

# Check logs
echo ""
echo "Checking logs..."
echo "----------------"
echo "Last startup script output:"
docker logs midnight-local-test 2>&1 | grep -E "(Startup|Executing|Starting|Configuring)" | tail -5

# Cleanup
echo ""
echo "Cleaning up..."
docker stop midnight-local-test >/dev/null 2>&1
docker rm midnight-local-test >/dev/null 2>&1

echo ""
echo "✓ Test complete"