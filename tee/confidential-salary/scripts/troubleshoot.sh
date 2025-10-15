#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m'

# Configuration
VM_NAME="${VM_NAME:-salary-analyzer-vm}"
ZONE="${ZONE:-us-central1-a}"

echo -e "${YELLOW}=== Troubleshooting Salary Analyzer Server ===${NC}"
echo ""

# Get VM IP
IP=$(gcloud compute instances describe "$VM_NAME" \
    --zone="$ZONE" \
    --format='get(networkInterfaces[0].accessConfigs[0].natIP)' 2>/dev/null)

if [ -z "$IP" ]; then
    echo -e "${RED}[ERROR]${NC} VM not found or has no external IP"
    exit 1
fi

echo -e "${GREEN}[INFO]${NC} VM External IP: $IP"
echo ""

# Check VM status
echo -e "${YELLOW}1. Checking VM Status...${NC}"
gcloud compute instances describe "$VM_NAME" --zone="$ZONE" \
    --format="table(name,status)" 2>/dev/null || echo "VM not found"
echo ""

# Check if we can SSH
echo -e "${YELLOW}2. Testing SSH connection...${NC}"
if gcloud compute ssh "$VM_NAME" --zone="$ZONE" --command="echo 'SSH connection successful'" 2>/dev/null; then
    echo -e "${GREEN}✓ SSH connection works${NC}"
else
    echo -e "${RED}✗ Cannot SSH to VM${NC}"
    exit 1
fi
echo ""

# Check if server binary exists
echo -e "${YELLOW}3. Checking if server binary exists...${NC}"
if gcloud compute ssh "$VM_NAME" --zone="$ZONE" --command="ls -la ~/confidential-salary-analyzer/server/target/release/server" 2>/dev/null; then
    echo -e "${GREEN}✓ Server binary found${NC}"
else
    echo -e "${RED}✗ Server binary not found - need to build${NC}"
    echo "Run: make gcp-deploy"
    exit 1
fi
echo ""

# Check systemd service status
echo -e "${YELLOW}4. Checking systemd service status...${NC}"
gcloud compute ssh "$VM_NAME" --zone="$ZONE" --command="sudo systemctl status salary-analyzer --no-pager" 2>/dev/null || true
echo ""

# Check if service is active
echo -e "${YELLOW}5. Checking if service is running...${NC}"
if gcloud compute ssh "$VM_NAME" --zone="$ZONE" --command="sudo systemctl is-active salary-analyzer" 2>/dev/null; then
    echo -e "${GREEN}✓ Service is active${NC}"
else
    echo -e "${RED}✗ Service is not running${NC}"
    
    # Try to start it
    echo -e "${YELLOW}Attempting to start service...${NC}"
    gcloud compute ssh "$VM_NAME" --zone="$ZONE" --command="
        sudo systemctl daemon-reload
        sudo systemctl start salary-analyzer
    " 2>/dev/null
    
    sleep 3
    
    if gcloud compute ssh "$VM_NAME" --zone="$ZONE" --command="sudo systemctl is-active salary-analyzer" 2>/dev/null; then
        echo -e "${GREEN}✓ Service started successfully${NC}"
    else
        echo -e "${RED}✗ Failed to start service${NC}"
        echo ""
        echo -e "${YELLOW}Recent logs:${NC}"
        gcloud compute ssh "$VM_NAME" --zone="$ZONE" --command="sudo journalctl -u salary-analyzer -n 20 --no-pager" 2>/dev/null || true
    fi
fi
echo ""

# Check if port 8080 is listening
echo -e "${YELLOW}6. Checking if port 8080 is listening...${NC}"
if gcloud compute ssh "$VM_NAME" --zone="$ZONE" --command="sudo netstat -tlnp | grep :8080" 2>/dev/null; then
    echo -e "${GREEN}✓ Port 8080 is listening${NC}"
else
    echo -e "${RED}✗ Port 8080 is not listening${NC}"
    
    # Try running server directly to see errors
    echo ""
    echo -e "${YELLOW}Trying to run server directly to see errors...${NC}"
    gcloud compute ssh "$VM_NAME" --zone="$ZONE" --command="
        source \$HOME/.cargo/env
        cd ~/confidential-salary-analyzer/server
        timeout 5 RUST_LOG=debug TDX_ENABLED=1 ./target/release/server 2>&1 | head -20
    " 2>/dev/null || true
fi
echo ""

# Check firewall rules
echo -e "${YELLOW}7. Checking firewall rules...${NC}"
if gcloud compute firewall-rules describe allow-salary-analyzer 2>/dev/null | grep -q "tcp:8080"; then
    echo -e "${GREEN}✓ Firewall rule exists for port 8080${NC}"
else
    echo -e "${RED}✗ Firewall rule missing${NC}"
    echo "Creating firewall rule..."
    gcloud compute firewall-rules create allow-salary-analyzer \
        --allow tcp:8080 \
        --source-ranges 0.0.0.0/0 \
        --target-tags http-server \
        --description "Allow Salary Analyzer server" 2>/dev/null || true
fi
echo ""

# Test HTTP connection
echo -e "${YELLOW}8. Testing HTTP connection...${NC}"
if curl -s "http://$IP:8080/health" --max-time 5 | jq . 2>/dev/null; then
    echo -e "${GREEN}✓ Server is responding to HTTP requests${NC}"
else
    echo -e "${RED}✗ Server is not responding on http://$IP:8080${NC}"
    
    # Check if it's a network issue
    echo ""
    echo -e "${YELLOW}Testing basic network connectivity...${NC}"
    if ping -c 1 "$IP" &>/dev/null; then
        echo -e "${GREEN}✓ VM is reachable via ping${NC}"
    else
        echo -e "${RED}✗ Cannot ping VM (might be blocked)${NC}"
    fi
fi
echo ""

# Summary
echo -e "${YELLOW}=== Troubleshooting Summary ===${NC}"
echo "VM IP: $IP"
echo "SSH: Working"

# Provide fix suggestions
echo ""
echo -e "${YELLOW}=== Suggested Fixes ===${NC}"
echo "1. If service is not running:"
echo "   make gcp-deploy"
echo ""
echo "2. To manually start the service:"
echo "   gcloud compute ssh $VM_NAME --zone=$ZONE"
echo "   sudo systemctl restart salary-analyzer"
echo "   sudo journalctl -fu salary-analyzer"
echo ""
echo "3. To test locally on the VM:"
echo "   gcloud compute ssh $VM_NAME --zone=$ZONE"
echo "   curl http://localhost:8080/health"
echo ""
echo "4. To check logs:"
echo "   make gcp-logs"