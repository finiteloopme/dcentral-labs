#!/bin/bash

# Update system packages
apt-get update && apt-get upgrade -y

# Install required packages
apt-get install -y docker.io docker-compose git curl wget

# Start and enable Docker
systemctl start docker
systemctl enable docker

# Add user to docker group
usermod -aG docker user

# Create application directory
mkdir -p /opt/privacy-defi
cd /opt/privacy-defi

# Clone or pull the latest code (if repository is available)
# git clone <repository-url> .

# For now, create a basic mock server setup
mkdir -p logs

# Create a simple mock server service file
cat > /etc/systemd/system/mock-server.service << 'EOF'
[Unit]
Description=Privacy DeFi Mock Server
After=docker.service
Requires=docker.service

[Service]
Type=simple
User=root
WorkingDirectory=/opt/privacy-defi
Restart=always
RestartSec=10
ExecStart=/usr/bin/docker-compose up --build
ExecStop=/usr/bin/docker-compose down

[Install]
WantedBy=multi-user.target
EOF

# Enable the service
systemctl enable mock-server

# Create a basic docker-compose.yml for the mock server
cat > /opt/privacy-defi/docker-compose.yml << 'EOF'
version: '3.8'

services:
  mock-server:
    image: node:18-alpine
    container_name: privacy-defi-mock-server
    ports:
      - "8080:8080"
      - "8545:8545"
    volumes:
      - ./logs:/app/logs
    working_dir: /app
    command: >
      sh -c "
        echo 'Starting mock server...' &&
        echo 'Mock server listening on port 8080' &&
        echo 'Mock blockchain RPC listening on port 8545' &&
        tail -f /dev/null
      "
    restart: unless-stopped
EOF

echo "Mock server setup completed successfully!"