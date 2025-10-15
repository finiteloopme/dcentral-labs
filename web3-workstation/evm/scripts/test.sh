#!/bin/bash

# Test container image and services
set -e

BLUE='\033[0;34m'
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}Testing container and services...${NC}\n"

# Find runtime
RUNTIME=$(command -v podman 2>/dev/null || command -v docker 2>/dev/null)
if [ -z "$RUNTIME" ]; then
    echo -e "${RED}No container runtime found${NC}"
    exit 1
fi

# Determine image
if [ -n "$1" ]; then
    IMAGE="$1"
else
    IMAGE="web3-workstation:local"
fi

echo "Testing image: $IMAGE"
echo ""

# Test 1: Check if image exists
echo -e "${BLUE}Test 1: Image availability${NC}"
if $RUNTIME images --format "{{.Repository}}:{{.Tag}}" | grep -q "^${IMAGE}$"; then
    echo -e "${GREEN}✓ Image exists${NC}"
else
    echo -e "${RED}✗ Image not found. Run: make local-build${NC}"
    exit 1
fi

# Test 2: Run container and test tools
echo -e "\n${BLUE}Test 2: Container tools${NC}"
$RUNTIME run --rm $IMAGE /bin/bash -c "
echo -n '  Foundry: '
forge --version | head -1 || echo 'FAILED'
echo -n '  Node.js: '
node --version || echo 'FAILED'
echo -n '  OpenCode: '
opencode --version 2>/dev/null || echo 'OK (TUI)'
"

# Test 3: Test services
echo -e "\n${BLUE}Test 3: Service endpoints${NC}"
CONTAINER_NAME="test-web3-workstation-$$"

# Start container in background
echo "Starting test container..."
$RUNTIME run -d --name $CONTAINER_NAME \
    -p 18000:80 \
    -p 18080:8080 \
    $IMAGE

# Wait for services to start
echo "Waiting for services to start..."
sleep 5

# Test endpoints
echo -e "\n${YELLOW}Testing endpoints:${NC}"

# Test Code-OSS
echo -n "  Code-OSS IDE (port 18000): "
if curl -s -o /dev/null -w "%{http_code}" http://localhost:18000 | grep -q "200\|302"; then
    echo -e "${GREEN}✓ Accessible${NC}"
else
    echo -e "${RED}✗ Not accessible${NC}"
fi

# Test OpenCode terminal
echo -n "  OpenCode Terminal (port 18080): "
if curl -s -o /dev/null -w "%{http_code}" http://localhost:18080 | grep -q "200"; then
    echo -e "${GREEN}✓ Accessible${NC}"
else
    echo -e "${RED}✗ Not accessible${NC}"
fi

# Test health endpoint
echo -n "  Health check (port 18080/health): "
HEALTH=$(curl -s http://localhost:18080/health 2>/dev/null)
if echo "$HEALTH" | grep -q "ok"; then
    echo -e "${GREEN}✓ Healthy${NC}"
    echo "    Response: $HEALTH"
else
    echo -e "${RED}✗ Failed${NC}"
fi

# Check container logs
echo -e "\n${BLUE}Container logs:${NC}"
$RUNTIME logs $CONTAINER_NAME | tail -10

# Cleanup
echo -e "\n${YELLOW}Cleaning up test container...${NC}"
$RUNTIME stop $CONTAINER_NAME >/dev/null 2>&1
$RUNTIME rm $CONTAINER_NAME >/dev/null 2>&1

echo -e "\n${GREEN}✓ Tests complete${NC}"
echo ""
echo "If services are not accessible, try:"
echo "  1. For Podman on macOS: make fix-podman"
echo "  2. Check firewall settings"
echo "  3. Run: make local-debug"