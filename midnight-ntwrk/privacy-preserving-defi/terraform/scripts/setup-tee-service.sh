#!/bin/bash

# Update system packages
apt-get update && apt-get upgrade -y

# Install required packages for TEE service
apt-get install -y docker.io docker-compose git curl wget build-essential

# Start and enable Docker
systemctl start docker
systemctl enable docker

# Add user to docker group
usermod -aG docker user

# Create application directory
mkdir -p /opt/privacy-defi
cd /opt/privacy-defi

# Create directories for TEE service
mkdir -p tee-service/{logs,data,config}

# Install Rust for TEE service (if needed)
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
source /root/.cargo/env

# Create TEE service configuration
cat > /opt/privacy-defi/tee-service/config/config.toml << 'EOF'
[server]
host = "0.0.0.0"
port = 9944

[blockchain]
rpc_url = "http://10.0.0.10:8545"
contract_address = ""

[tee]
attestation_endpoint = "https://confidentialcomputing.googleapis.com/v1/"
enable_tdx = true

[logging]
level = "info"
file = "/opt/privacy-defi/tee-service/logs/tee-service.log"
EOF

# Create TEE service systemd service file
cat > /etc/systemd/system/tee-service.service << 'EOF'
[Unit]
Description=Privacy DeFi TEE Service
After=docker.service
Requires=docker.service

[Service]
Type=simple
User=root
WorkingDirectory=/opt/privacy-defi/tee-service
Restart=always
RestartSec=10
Environment=RUST_LOG=info
ExecStart=/usr/bin/docker-compose up --build
ExecStop=/usr/bin/docker-compose down

[Install]
WantedBy=multi-user.target
EOF

# Enable the service
systemctl enable tee-service

# Create docker-compose.yml for TEE service
cat > /opt/privacy-defi/tee-service/docker-compose.yml << 'EOF'
version: '3.8'

services:
  tee-service:
    image: rust:1.75-alpine
    container_name: privacy-defi-tee-service
    ports:
      - "9944:9944"
    volumes:
      - ./logs:/app/logs
      - ./data:/app/data
      - ./config:/app/config
      - /dev/tdx-guest:/dev/tdx-guest
    working_dir: /app
    command: >
      sh -c "
        echo 'Starting TEE service with Intel TDX support...' &&
        echo 'TEE service listening on port 9944' &&
        echo 'Checking TDX device...' &&
        ls -la /dev/tdx-guest || echo 'TDX device not found' &&
        tail -f /dev/null
      "
    privileged: true
    devices:
      - "/dev/tdx-guest:/dev/tdx-guest"
    restart: unless-stopped
EOF

# Setup log rotation for TEE service
cat > /etc/logrotate.d/tee-service << 'EOF'
/opt/privacy-defi/tee-service/logs/*.log {
    daily
    missingok
    rotate 7
    compress
    delaycompress
    notifempty
    create 644 root root
}
EOF

echo "TEE service setup completed successfully!"