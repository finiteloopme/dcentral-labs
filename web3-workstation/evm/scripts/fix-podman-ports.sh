#!/bin/bash

# Fix Podman port forwarding issues on macOS

BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}Podman Port Forwarding Fix${NC}\n"

# Check if on macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    echo -e "${YELLOW}This script is for macOS only${NC}"
    exit 0
fi

# Check if podman is installed
if ! command -v podman &> /dev/null; then
    echo -e "${RED}Podman is not installed${NC}"
    exit 1
fi

echo "This script will help fix Podman networking issues on macOS."
echo ""
echo "Choose a solution:"
echo "  1. SSH tunnel with port forwarding (recommended)"
echo "  2. Restart Podman machine with root privileges"
echo "  3. Manual port forward setup"
echo ""
read -p "Select (1-3): " choice

case $choice in
    1)
        echo -e "\n${BLUE}Setting up SSH tunnel...${NC}"
        echo "This will forward ports 8000 and 8080 from the Podman VM to your Mac"
        echo ""
        echo "Run this command in a separate terminal:"
        echo ""
        echo -e "${GREEN}podman machine ssh -- -L 8000:localhost:8000 -L 8080:localhost:8080 -N${NC}"
        echo ""
        echo "Keep that terminal open while using the container."
        echo "Then in another terminal, run: make local"
        ;;
    
    2)
        echo -e "\n${BLUE}Restarting Podman machine...${NC}"
        read -p "This will stop all running containers. Continue? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            podman machine stop
            podman machine set --rootful
            podman machine start
            echo -e "${GREEN}Podman machine restarted in rootful mode${NC}"
            echo "Now run: make local"
        fi
        ;;
    
    3)
        echo -e "\n${BLUE}Manual Port Forwarding${NC}"
        echo ""
        echo "1. First, get the container IP:"
        echo "   podman inspect web3-workstation-local | grep IPAddress"
        echo ""
        echo "2. SSH into the Podman machine:"
        echo "   podman machine ssh"
        echo ""
        echo "3. Inside the machine, forward ports:"
        echo "   sudo iptables -t nat -A PREROUTING -p tcp --dport 8000 -j DNAT --to-destination CONTAINER_IP:80"
        echo "   sudo iptables -t nat -A PREROUTING -p tcp --dport 8080 -j DNAT --to-destination CONTAINER_IP:8080"
        echo ""
        echo "4. Exit and test:"
        echo "   curl http://localhost:8000"
        ;;
esac

echo ""
echo -e "${YELLOW}Additional Tips:${NC}"
echo "• Use 'make local-debug' or './scripts/local-dev.sh debug' to diagnose issues"
echo "• Try running with --rootful flag: './scripts/local-dev.sh run --rootful'"
echo "• Check Podman machine status: 'podman machine list'"
echo "• View container logs: 'podman logs web3-workstation-local'"