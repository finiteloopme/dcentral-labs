#!/bin/bash

# Comprehensive network debugging script for Linux

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}=== Web3 Workstation Network Debugging ===${NC}\n"

# Detect runtime
RUNTIME=$(command -v podman 2>/dev/null || command -v docker 2>/dev/null)
RUNTIME_NAME=$(basename $RUNTIME 2>/dev/null || echo "none")
CONTAINER_NAME="web3-workstation-local"

echo -e "${YELLOW}1. System Information${NC}"
echo "OS: $(uname -a | cut -d' ' -f1,3,12)"
echo "Runtime: $RUNTIME_NAME"
echo ""

echo -e "${YELLOW}2. Container Status${NC}"
if [ -n "$RUNTIME" ]; then
    if $RUNTIME ps --format "table {{.Names}}\t{{.Status}}" | grep -q "$CONTAINER_NAME"; then
        echo -e "${GREEN}✓ Container is running${NC}"
        
        # Get container details
        echo -e "\n${YELLOW}3. Container Details${NC}"
        $RUNTIME inspect $CONTAINER_NAME --format '{{.State.Status}}' | xargs echo "Status:"
        $RUNTIME inspect $CONTAINER_NAME --format '{{.NetworkSettings.IPAddress}}' | xargs echo "IP Address:"
        
        echo -e "\n${YELLOW}4. Port Mappings${NC}"
        $RUNTIME port $CONTAINER_NAME
        
        echo -e "\n${YELLOW}5. Container Processes${NC}"
        $RUNTIME exec $CONTAINER_NAME ps aux | grep -E "node|code-server|opencode" || echo "No processes found"
        
        echo -e "\n${YELLOW}6. Container Network Test${NC}"
        echo "Testing from inside container:"
        $RUNTIME exec $CONTAINER_NAME bash -c "curl -s -o /dev/null -w 'localhost:8000: %{http_code}\n' http://localhost:8000 || echo 'localhost:8000: Failed'"
        $RUNTIME exec $CONTAINER_NAME bash -c "curl -s -o /dev/null -w 'localhost:8080: %{http_code}\n' http://localhost:8080 || echo 'localhost:8080: Failed'"
        
        echo -e "\n${YELLOW}7. Container Logs (last 20 lines)${NC}"
        $RUNTIME logs --tail 20 $CONTAINER_NAME
        
    else
        echo -e "${RED}✗ Container not running${NC}"
        echo "Start with: make local"
        exit 1
    fi
else
    echo -e "${RED}No container runtime found${NC}"
    exit 1
fi

echo -e "\n${YELLOW}8. Host Network Tests${NC}"

# Check if ports are listening
echo "Checking listening ports:"
ss -tlnp 2>/dev/null | grep -E "8000|8080" || netstat -tlnp 2>/dev/null | grep -E "8000|8080" || echo "No ports found listening"

# Test localhost
echo -e "\nTesting localhost connections:"
timeout 2 curl -s -o /dev/null -w "localhost:8000: %{http_code}\n" http://localhost:8000 || echo "localhost:8000: Connection failed"
timeout 2 curl -s -o /dev/null -w "localhost:8080: %{http_code}\n" http://localhost:8080 || echo "localhost:8080: Connection failed"

# Test 127.0.0.1
echo -e "\nTesting 127.0.0.1 connections:"
timeout 2 curl -s -o /dev/null -w "127.0.0.1:8000: %{http_code}\n" http://127.0.0.1:8000 || echo "127.0.0.1:8000: Connection failed"
timeout 2 curl -s -o /dev/null -w "127.0.0.1:8080: %{http_code}\n" http://127.0.0.1:8080 || echo "127.0.0.1:8080: Connection failed"

# Test 0.0.0.0
echo -e "\nTesting 0.0.0.0 connections:"
timeout 2 curl -s -o /dev/null -w "0.0.0.0:8000: %{http_code}\n" http://0.0.0.0:8000 || echo "0.0.0.0:8000: Connection failed"
timeout 2 curl -s -o /dev/null -w "0.0.0.0:8080: %{http_code}\n" http://0.0.0.0:8080 || echo "0.0.0.0:8080: Connection failed"

echo -e "\n${YELLOW}9. Firewall Status${NC}"
# Check iptables
if command -v iptables &>/dev/null; then
    echo "iptables rules for ports 8000/8080:"
    sudo iptables -L -n 2>/dev/null | grep -E "8000|8080" || echo "No specific rules found"
fi

# Check firewalld
if command -v firewall-cmd &>/dev/null; then
    echo "firewalld status:"
    sudo firewall-cmd --state 2>/dev/null || echo "firewalld not running"
fi

# Check ufw
if command -v ufw &>/dev/null; then
    echo "ufw status:"
    sudo ufw status 2>/dev/null | grep -E "8000|8080" || echo "ufw not configured or no rules"
fi

echo -e "\n${YELLOW}10. Network Interfaces${NC}"
ip addr show | grep -E "inet |UP" | grep -v "inet6"

echo -e "\n${YELLOW}11. Diagnostic Summary${NC}"

# Podman-specific checks
if [ "$RUNTIME_NAME" = "podman" ]; then
    echo -e "\n${BLUE}Podman-specific checks:${NC}"
    
    # Check if running rootless
    if [ "$EUID" -ne 0 ]; then
        echo "Running in rootless mode"
        echo "Checking podman network:"
        podman network ls
        
        # Check if using slirp4netns
        if podman info 2>/dev/null | grep -q "slirp4netns"; then
            echo -e "${YELLOW}Using slirp4netns for networking${NC}"
            echo "Note: This can cause port forwarding issues"
        fi
    fi
    
    # Check cgroup version
    echo -e "\nCgroup version:"
    stat -fc %T /sys/fs/cgroup/ 2>/dev/null || echo "Unable to determine"
fi

echo -e "\n${YELLOW}12. Suggested Fixes${NC}"

# Analyze and suggest fixes
ISSUES_FOUND=false

# Check if services are running inside container
if ! $RUNTIME exec $CONTAINER_NAME pgrep -f "code-server" &>/dev/null; then
    echo -e "${RED}• code-server is not running inside container${NC}"
    echo "  Fix: Rebuild container with: make local-build"
    ISSUES_FOUND=true
fi

if ! $RUNTIME exec $CONTAINER_NAME pgrep -f "node.*server.js" &>/dev/null; then
    echo -e "${RED}• OpenCode terminal server is not running${NC}"
    echo "  Fix: Check container logs for startup errors"
    ISSUES_FOUND=true
fi

# Check port binding
if ! ss -tlnp 2>/dev/null | grep -q ":8000\|:8080"; then
    if [ "$RUNTIME_NAME" = "podman" ]; then
        echo -e "${RED}• Ports not bound on host${NC}"
        echo "  Possible fixes:"
        echo "  1. Try running with different network mode:"
        echo "     podman run --network=host ..."
        echo "  2. Try with explicit IP binding:"
        echo "     podman run -p 127.0.0.1:8000:8000 -p 127.0.0.1:8080:8080 ..."
        echo "  3. Check SELinux (if enabled):"
        echo "     sudo setenforce 0  # Temporarily disable to test"
    fi
    ISSUES_FOUND=true
fi

if [ "$ISSUES_FOUND" = "false" ]; then
    echo -e "${GREEN}✓ No obvious issues found${NC}"
    echo "Try:"
    echo "  1. Clear browser cache and cookies"
    echo "  2. Try incognito/private browsing mode"
    echo "  3. Check browser console for errors"
fi

echo -e "\n${BLUE}=== End of Diagnostics ===${NC}"