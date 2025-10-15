#!/bin/bash

# Quick fix script to get the server running

VM_NAME="${VM_NAME:-salary-analyzer-vm}"
ZONE="${ZONE:-us-central1-a}"

echo "Quick fix: Building and starting server on VM..."

gcloud compute ssh "$VM_NAME" --zone="$ZONE" --command='
    # Ensure Rust is available
    source $HOME/.cargo/env 2>/dev/null || true
    
    # Go to project directory
    cd ~/confidential-salary-analyzer
    
    # Build with workspace structure
    echo "Building server..."
    cargo build --release --bin server
    
    # Find the server binary
    SERVER_BIN=$(find . -name "server" -type f -executable | grep release | head -1)
    
    if [ -n "$SERVER_BIN" ]; then
        echo "Found server at: $SERVER_BIN"
        
        # Copy to standard location
        sudo cp "$SERVER_BIN" /usr/local/bin/salary-analyzer-server
        sudo chmod +x /usr/local/bin/salary-analyzer-server
        
        # Create simple systemd service
        echo "[Unit]
Description=Salary Analyzer Server
After=network.target

[Service]
Type=simple
Environment=\"TDX_ENABLED=1\"
Environment=\"RUST_LOG=info\"
ExecStart=/usr/local/bin/salary-analyzer-server
Restart=always

[Install]
WantedBy=multi-user.target" | sudo tee /etc/systemd/system/salary-analyzer.service
        
        # Start service
        sudo systemctl daemon-reload
        sudo systemctl restart salary-analyzer
        
        sleep 3
        
        # Check status
        if sudo systemctl is-active salary-analyzer; then
            echo "✓ Service is running!"
            echo ""
            echo "Testing localhost..."
            curl -s http://localhost:8080/health | head -20
        else
            echo "✗ Service failed. Running directly..."
            sudo TDX_ENABLED=1 RUST_LOG=debug /usr/local/bin/salary-analyzer-server &
            sleep 3
            curl -s http://localhost:8080/health
        fi
    else
        echo "Error: Could not find server binary"
        echo "Contents of target:"
        find target -type f -name "server" 2>/dev/null
        exit 1
    fi
'

# Test from outside
IP=$(gcloud compute instances describe "$VM_NAME" \
    --zone="$ZONE" \
    --format='get(networkInterfaces[0].accessConfigs[0].natIP)' 2>/dev/null)

echo ""
echo "Testing from outside at http://$IP:8080 ..."
curl -s "http://$IP:8080/health" --max-time 5 | jq . || echo "Not accessible yet"