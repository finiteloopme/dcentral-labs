#!/bin/bash

set -e

# Configuration
VM_NAME="${VM_NAME:-salary-analyzer-vm}"
ZONE="${ZONE:-us-central1-a}"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${YELLOW}=== Remote Build on GCP VM ===${NC}"
echo ""

# Check if VM exists
if ! gcloud compute instances describe "$VM_NAME" --zone="$ZONE" &>/dev/null; then
    echo -e "${RED}[ERROR]${NC} VM '$VM_NAME' does not exist"
    exit 1
fi

echo -e "${GREEN}[INFO]${NC} Connected to VM: $VM_NAME"

# Check if source exists
echo -e "${YELLOW}Checking if source code exists on VM...${NC}"
if ! gcloud compute ssh "$VM_NAME" --zone="$ZONE" --command="ls ~/confidential-salary-analyzer/Cargo.toml" &>/dev/null; then
    echo -e "${RED}[ERROR]${NC} Source code not found. Run 'make gcp-deploy' first"
    exit 1
fi

# Install Rust if needed
echo -e "${YELLOW}Checking Rust installation...${NC}"
gcloud compute ssh "$VM_NAME" --zone="$ZONE" --command='
    if ! command -v rustc &>/dev/null; then
        echo "Installing Rust..."
        curl -sSf https://sh.rustup.rs > /tmp/rustup.sh && \
        sh /tmp/rustup.sh -y && \
        rm /tmp/rustup.sh
    fi
    source $HOME/.cargo/env
    rustc --version
    cargo --version
'

# Clean previous build if requested
if [ "$1" == "--clean" ]; then
    echo -e "${YELLOW}Cleaning previous build...${NC}"
    gcloud compute ssh "$VM_NAME" --zone="$ZONE" --command='
        cd ~/confidential-salary-analyzer && \
        cargo clean
    '
fi

# Build the project
echo -e "${YELLOW}Building project on VM...${NC}"
echo -e "${YELLOW}This will take several minutes on first run...${NC}"

gcloud compute ssh "$VM_NAME" --zone="$ZONE" --command='
    source $HOME/.cargo/env
    cd ~/confidential-salary-analyzer
    
    echo "=== Build Environment ==="
    echo "Rust: $(rustc --version)"
    echo "Cargo: $(cargo --version)"
    echo "Directory: $(pwd)"
    echo "======================="
    echo ""
    
    # Build all components
    echo "Building all components..."
    cargo build --release --all
    
    echo ""
    echo "=== Build Complete ==="
    
    # Find and verify binaries
    echo "Looking for binaries..."
    find . -name "server" -type f -executable 2>/dev/null | head -5
    find . -name "client" -type f -executable 2>/dev/null | head -5
    
    # Check both possible locations
    SERVER_BIN=""
    if [ -f "target/release/server" ]; then
        SERVER_BIN="target/release/server"
    elif [ -f "server/target/release/server" ]; then
        SERVER_BIN="server/target/release/server"
    fi
    
    CLIENT_BIN=""
    if [ -f "target/release/client" ]; then
        CLIENT_BIN="target/release/client"
    elif [ -f "client/target/release/client" ]; then
        CLIENT_BIN="client/target/release/client"
    fi
    
    if [ -n "$SERVER_BIN" ]; then
        echo "✓ Server binary: $(ls -lh $SERVER_BIN | awk "{print \$5}")"
        # Copy to expected location for systemd
        sudo mkdir -p /usr/local/bin
        sudo cp $SERVER_BIN /usr/local/bin/salary-analyzer-server
        sudo chmod +x /usr/local/bin/salary-analyzer-server
    else
        echo "✗ Server binary not found"
        echo "Contents of target directory:"
        ls -la target/release/ 2>/dev/null || echo "No target/release directory"
        exit 1
    fi
    
    if [ -n "$CLIENT_BIN" ]; then
        echo "✓ Client binary: $(ls -lh $CLIENT_BIN | awk "{print \$5}")"
    else
        echo "✗ Client binary not found"
    fi
'

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Build completed successfully${NC}"
    
    # Update systemd service
    echo -e "${YELLOW}Updating systemd service...${NC}"
    gcloud compute ssh "$VM_NAME" --zone="$ZONE" --command='
        # Find the server binary
        SERVER_BIN=""
        if [ -f "$HOME/confidential-salary-analyzer/target/release/server" ]; then
            SERVER_BIN="$HOME/confidential-salary-analyzer/target/release/server"
        elif [ -f "/usr/local/bin/salary-analyzer-server" ]; then
            SERVER_BIN="/usr/local/bin/salary-analyzer-server"
        fi
        
        if [ -n "$SERVER_BIN" ]; then
            cat <<EOF | sudo tee /etc/systemd/system/salary-analyzer.service > /dev/null
[Unit]
Description=Confidential Salary Analyzer Server
After=network.target

[Service]
Type=simple
User=$USER
WorkingDirectory=$HOME/confidential-salary-analyzer
Environment="TDX_ENABLED=1"
Environment="RUST_LOG=info"
ExecStart=$SERVER_BIN
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF
            
            sudo systemctl daemon-reload
            sudo systemctl restart salary-analyzer
            sleep 3
            
            if sudo systemctl is-active salary-analyzer &>/dev/null; then
                echo "✓ Service started successfully"
                sudo systemctl status salary-analyzer --no-pager | head -10
            else
                echo "✗ Service failed to start"
                echo "Attempting to run directly to see error:"
                timeout 5 $SERVER_BIN 2>&1 | head -20 || true
                echo ""
                echo "Service logs:"
                sudo journalctl -u salary-analyzer -n 20 --no-pager
            fi
        else
            echo "Error: Could not find server binary"
            exit 1
        fi
    '
else
    echo -e "${RED}✗ Build failed${NC}"
    exit 1
fi

# Get IP and test
IP=$(gcloud compute instances describe "$VM_NAME" \
    --zone="$ZONE" \
    --format='get(networkInterfaces[0].accessConfigs[0].natIP)' 2>/dev/null)

echo ""
echo -e "${GREEN}Server should be available at: http://$IP:8080${NC}"
echo ""
echo "Testing health endpoint..."
sleep 3

if curl -s "http://$IP:8080/health" --max-time 5 | jq . 2>/dev/null; then
    echo -e "${GREEN}✓ Server is responding!${NC}"
else
    echo -e "${YELLOW}⚠ Server may still be starting. Try again in a few seconds.${NC}"
fi