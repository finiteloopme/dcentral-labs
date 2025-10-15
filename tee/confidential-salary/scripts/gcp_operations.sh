#!/bin/bash

set -e

# Configuration with defaults
PROJECT_ID="${PROJECT_ID:-$(gcloud config get-value project 2>/dev/null)}"
ZONE="${ZONE:-us-central1-a}"
REGION="${REGION:-us-central1}"
VM_NAME="${VM_NAME:-salary-analyzer-vm}"
MACHINE_TYPE="${MACHINE_TYPE:-c3-standard-4}"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Helper functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

check_config() {
    if [ -z "$PROJECT_ID" ]; then
        log_error "PROJECT_ID is not set. Run: gcloud config set project YOUR_PROJECT_ID"
        exit 1
    fi
    log_info "Using project: $PROJECT_ID"
}

# Main operations
create_vm() {
    check_config
    
    log_info "Creating Confidential VM with Intel TDX..."
    
    if gcloud compute instances describe "$VM_NAME" --zone="$ZONE" &>/dev/null; then
        log_warn "VM '$VM_NAME' already exists"
        return 0
    fi
    
    gcloud compute instances create "$VM_NAME" \
        --project="$PROJECT_ID" \
        --zone="$ZONE" \
        --machine-type="$MACHINE_TYPE" \
        --maintenance-policy=TERMINATE \
        --confidential-compute-type=TDX \
        --image-family=ubuntu-2204-lts \
        --image-project=ubuntu-os-cloud \
        --tags=http-server,https-server,ssh \
        --metadata=startup-script='#!/bin/bash
            apt-get update
            apt-get install -y build-essential git'
    
    log_info "Creating firewall rule for port 8080..."
    gcloud compute firewall-rules create allow-salary-analyzer \
        --project="$PROJECT_ID" \
        --allow tcp:8080 \
        --source-ranges 0.0.0.0/0 \
        --target-tags http-server \
        --description "Allow Salary Analyzer server" \
        2>/dev/null || log_warn "Firewall rule already exists"
    
    log_info "VM created successfully"
    show_vm_ip
}

deploy() {
    check_config
    
    log_info "Deploying to Confidential VM..."
    
    # Check if VM exists
    if ! gcloud compute instances describe "$VM_NAME" --zone="$ZONE" &>/dev/null; then
        log_error "VM '$VM_NAME' does not exist. Run 'create-vm' first."
        exit 1
    fi
    
    # Install dependencies and Rust
    log_info "Installing dependencies..."
    gcloud compute ssh "$VM_NAME" --zone="$ZONE" --command='
        sudo apt-get update && \
        sudo apt-get install -y build-essential curl git pkg-config libssl-dev'
    
    log_info "Installing Rust on VM..."
    gcloud compute ssh "$VM_NAME" --zone="$ZONE" --command='
        if ! command -v rustc &> /dev/null; then
            echo "Installing Rust..."
            curl -sSf https://sh.rustup.rs > /tmp/rustup.sh && \
            sh /tmp/rustup.sh -y && \
            rm /tmp/rustup.sh
        fi
        
        # Verify installation
        source $HOME/.cargo/env
        rustc --version || { echo "Rust installation failed"; exit 1; }'
    
    # Copy source code
    log_info "Copying source code..."
    # Create a tarball excluding unwanted files
    tar czf /tmp/salary-analyzer.tar.gz \
        --exclude='target' \
        --exclude='.git' \
        --exclude='*.swp' \
        --exclude='Dockerfile.deterministic' \
        .
    
    # Copy the tarball to VM
    gcloud compute scp /tmp/salary-analyzer.tar.gz \
        "$VM_NAME":/tmp/ \
        --zone="$ZONE"
    
    # Extract on VM
    gcloud compute ssh "$VM_NAME" --zone="$ZONE" --command='
        mkdir -p ~/confidential-salary-analyzer && \
        tar xzf /tmp/salary-analyzer.tar.gz -C ~/confidential-salary-analyzer && \
        rm /tmp/salary-analyzer.tar.gz'
    
    # Clean up local tarball
    rm -f /tmp/salary-analyzer.tar.gz
    
    # Build on VM
    log_info "Building on VM (this may take several minutes)..."
    log_info "Note: First build will download dependencies and may take 5-10 minutes"
    
    # Build with proper error handling and verbose output
    if ! gcloud compute ssh "$VM_NAME" --zone="$ZONE" --command='
        source $HOME/.cargo/env && \
        cd ~/confidential-salary-analyzer && \
        echo "Rust version: $(rustc --version)" && \
        echo "Starting build..." && \
        cargo build --release --verbose 2>&1 | tee /tmp/build.log | grep -E "Compiling|Building|Finished|error" || true
        
        # Check if build succeeded
        if [ -f "server/target/release/server" ]; then
            echo "✓ Server binary built successfully"
            ls -la server/target/release/server
            exit 0
        else
            echo "✗ Build failed. Last 50 lines of build log:"
            tail -50 /tmp/build.log
            exit 1
        fi'; then
        
        log_error "Build failed on VM. Checking for common issues..."
        
        # Check disk space
        gcloud compute ssh "$VM_NAME" --zone="$ZONE" --command='
            echo "Disk space:"
            df -h | grep -E "^/dev|Filesystem"
            echo ""
            echo "Memory:"
            free -h
        '
        
        exit 1
    fi
    
    # Setup systemd service
    log_info "Setting up systemd service..."
    create_systemd_service
    
    # Start service
    log_info "Starting service..."
    gcloud compute ssh "$VM_NAME" --zone="$ZONE" --command='
        sudo systemctl daemon-reload && \
        sudo systemctl enable salary-analyzer && \
        sudo systemctl restart salary-analyzer'
    
    # Wait for service to start
    sleep 3
    
    # Verify service is running
    log_info "Verifying service status..."
    if gcloud compute ssh "$VM_NAME" --zone="$ZONE" --command="sudo systemctl is-active salary-analyzer" &>/dev/null; then
        log_info "Service is running successfully"
    else
        log_error "Service failed to start. Checking logs..."
        gcloud compute ssh "$VM_NAME" --zone="$ZONE" --command="sudo journalctl -u salary-analyzer -n 20 --no-pager"
        log_error "Deployment may have issues. Run 'make gcp-troubleshoot' for diagnosis"
    fi
    
    log_info "Deployment complete"
    show_vm_ip
    
    # Test health endpoint
    local IP=$(get_vm_ip)
    if [ -n "$IP" ]; then
        log_info "Testing server health endpoint..."
        sleep 2
        if curl -s "http://$IP:8080/health" --max-time 5 | jq . 2>/dev/null; then
            log_info "✓ Server is responding correctly!"
        else
            log_warn "Server may not be ready yet. Try 'make gcp-status' in a few seconds"
        fi
    fi
}

create_systemd_service() {
    gcloud compute ssh "$VM_NAME" --zone="$ZONE" --command='
        # Find the server binary
        SERVER_BIN=""
        if [ -f "$HOME/confidential-salary-analyzer/target/release/server" ]; then
            SERVER_BIN="$HOME/confidential-salary-analyzer/target/release/server"
        elif [ -f "$HOME/confidential-salary-analyzer/server/target/release/server" ]; then
            SERVER_BIN="$HOME/confidential-salary-analyzer/server/target/release/server"
        elif [ -f "/usr/local/bin/salary-analyzer-server" ]; then
            SERVER_BIN="/usr/local/bin/salary-analyzer-server"
        fi
        
        if [ -z "$SERVER_BIN" ]; then
            echo "Error: Server binary not found"
            exit 1
        fi
        
        echo "Using server binary: $SERVER_BIN"
        
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
    '
}

ssh_vm() {
    check_config
    log_info "Connecting to VM..."
    gcloud compute ssh "$VM_NAME" --zone="$ZONE"
}

status() {
    check_config
    
    echo -e "${YELLOW}=== VM Status ===${NC}"
    if gcloud compute instances describe "$VM_NAME" --zone="$ZONE" &>/dev/null; then
        gcloud compute instances describe "$VM_NAME" --zone="$ZONE" --format="table(
            name,
            status,
            machineType.scope(machineTypes),
            networkInterfaces[0].accessConfigs[0].natIP:label=EXTERNAL_IP
        )"
    else
        log_error "VM not found"
        return 1
    fi
    
    echo -e "\n${YELLOW}=== Server Status ===${NC}"
    if gcloud compute ssh "$VM_NAME" --zone="$ZONE" --command="sudo systemctl is-active salary-analyzer" &>/dev/null; then
        gcloud compute ssh "$VM_NAME" --zone="$ZONE" --command="sudo systemctl status salary-analyzer --no-pager | head -10"
    else
        log_warn "Server is not running"
    fi
    
    echo -e "\n${YELLOW}=== Health Check ===${NC}"
    local IP=$(get_vm_ip)
    if [ -n "$IP" ]; then
        if curl -s "http://$IP:8080/health" --max-time 5 | jq . 2>/dev/null; then
            log_info "Health check passed"
        else
            log_error "Health check failed"
        fi
    fi
}

logs() {
    check_config
    log_info "Fetching recent server logs..."
    gcloud compute ssh "$VM_NAME" --zone="$ZONE" --command="
        sudo journalctl -u salary-analyzer -n 50 --no-pager"
}

cleanup() {
    check_config
    
    echo -e "${RED}⚠️  WARNING: This will delete all resources${NC}"
    echo "Resources to be deleted:"
    echo "  - VM: $VM_NAME"
    echo "  - Firewall rule: allow-salary-analyzer"
    echo ""
    read -p "Are you sure? (y/N) " -n 1 -r
    echo ""
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        log_info "Deleting VM..."
        gcloud compute instances delete "$VM_NAME" --zone="$ZONE" --quiet || true
        
        log_info "Deleting firewall rule..."
        gcloud compute firewall-rules delete allow-salary-analyzer --quiet 2>/dev/null || true
        
        log_info "Cleanup complete"
    else
        log_warn "Cleanup cancelled"
    fi
}

get_vm_ip() {
    gcloud compute instances describe "$VM_NAME" \
        --zone="$ZONE" \
        --format='get(networkInterfaces[0].accessConfigs[0].natIP)' 2>/dev/null
}

show_vm_ip() {
    local IP=$(get_vm_ip)
    if [ -n "$IP" ]; then
        log_info "VM External IP: $IP"
        log_info "Server URL: http://$IP:8080"
    fi
}

monitor() {
    check_config
    log_info "Starting monitoring dashboard (Ctrl+C to exit)..."
    watch -n 5 "gcloud compute ssh $VM_NAME --zone=$ZONE --command='
        echo \"=== Server Status ===\"
        sudo systemctl status salary-analyzer --no-pager | head -15
        echo \"\"
        echo \"=== Recent Logs ===\"
        sudo journalctl -u salary-analyzer -n 10 --no-pager
    ' 2>/dev/null"
}

test_remote() {
    check_config
    local IP=$(get_vm_ip)
    
    if [ -z "$IP" ]; then
        log_error "VM not found or has no external IP"
        exit 1
    fi
    
    log_info "Testing remote server at http://$IP:8080"
    
    # Check if client is built
    if [ ! -f "client/target/release/client" ]; then
        log_warn "Client not built, building now..."
        cargo build --release -p client
    fi
    
    SERVER_URL="http://$IP:8080" ./client/target/release/client demo
}

# Main script logic
case "${1:-}" in
    create-vm)
        create_vm
        ;;
    deploy)
        deploy
        ;;
    ssh)
        ssh_vm
        ;;
    status)
        status
        ;;
    logs)
        logs
        ;;
    cleanup)
        cleanup
        ;;
    monitor)
        monitor
        ;;
    test)
        test_remote
        ;;
    ip)
        show_vm_ip
        ;;
    full-setup)
        create_vm
        deploy
        status
        ;;
    help|"")
        echo "GCP Operations for Confidential Salary Analyzer"
        echo ""
        echo "Usage: $0 <command>"
        echo ""
        echo "Commands:"
        echo "  create-vm    - Create GCP Confidential VM with TDX"
        echo "  deploy       - Deploy server to VM"
        echo "  ssh          - SSH into VM"
        echo "  status       - Check VM and server status"
        echo "  logs         - View server logs"
        echo "  cleanup      - Delete all resources"
        echo "  monitor      - Live monitoring dashboard"
        echo "  test         - Test remote server"
        echo "  ip           - Show VM external IP"
        echo "  full-setup   - Complete setup (create + deploy)"
        echo ""
        echo "Environment Variables:"
        echo "  PROJECT_ID   = ${PROJECT_ID:-not set}"
        echo "  ZONE         = $ZONE"
        echo "  VM_NAME      = $VM_NAME"
        echo "  MACHINE_TYPE = $MACHINE_TYPE"
        ;;
    *)
        log_error "Unknown command: $1"
        echo "Run '$0 help' for usage"
        exit 1
        ;;
esac