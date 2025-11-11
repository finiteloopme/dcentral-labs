#!/bin/bash
# Midnight Vibe Platform - Startup Script
# This script runs as root during workstation startup

echo "🌙 Initializing Midnight Vibe Platform..."

# Start PostgreSQL
echo "📡 Starting PostgreSQL..."
# Fix permissions and start PostgreSQL
mkdir -p /var/run/postgresql
chown postgres:postgres /var/run/postgresql
sudo -u postgres /usr/lib/postgresql/16/bin/pg_ctl -D /var/lib/postgresql/data -l /var/log/postgresql.log start &

# Start Midnight Node (with mock to avoid DB connection issues)
echo "🔗 Starting Midnight Node..."
# Create mock registrations file for midnight node
mkdir -p /tmp/midnight-mock
cat > /tmp/midnight-mock/registrations.json << 'EOF'
{
  "registrations": []
}
EOF

# Set environment variables for mock mode
export MIDNIGHT_USE_MAIN_CHAIN_FOLLOWER_MOCK=true

/usr/local/bin/midnight-node \
  --dev \
  --rpc-external \
  --ws-external \
  --use-main-chain-follower-mock \
  --main-chain-follower-mock-registrations-file=/tmp/midnight-mock/registrations.json \
  --rpc-cors=all &

# Start Proof Server
echo "🔐 Starting Proof Server..."
/usr/local/bin/midnight-proof-server --network testnet --port 8081 &

# Start Indexer (with config fix)
echo "📊 Starting Indexer..."
cd /tmp
cp /tmp/indexer-config.yaml /tmp/config.yaml
/usr/local/bin/midnight-indexer-standalone &

# Code OSS port is now configured to use 8080 in custom startup script

# Start OpenCode AI Assistant setup
echo "🤖 Setting up OpenCode AI Assistant..."
if [ ! -f "/usr/local/opencode/opencode" ]; then
    mkdir -p /usr/local/opencode
    ARCH=$(uname -m)
    if [ "$ARCH" = "x86_64" ]; then ARCH="x64"; fi
    curl -L "https://github.com/sst/opencode/releases/latest/download/opencode-linux-${ARCH}.zip" -o /tmp/opencode.zip
    unzip -p /tmp/opencode.zip opencode > /usr/local/opencode/opencode
    chmod +x /usr/local/opencode/opencode
    rm /tmp/opencode.zip
fi

# Set proper permissions for all users
chmod -R 755 /usr/local/opencode

# Add OpenCode to system PATH for all users
echo 'export PATH="/usr/local/opencode:$PATH"' >> /etc/bash.bashrc
echo 'export PATH="/usr/local/opencode:$PATH"' >> /etc/profile

# Create global OpenCode config directory and config file for user
mkdir -p /home/user/.config/opencode
cat > /home/user/.config/opencode/opencode.json << 'EOF'
{
  "$schema": "https://opencode.ai/config.json",
  "provider": {
    "google-vertex-anthropic": {
      "name": "Google Vertex AI Anthropic",
      "options": {
        "project": "{env:GOOGLE_VERTEX_PROJECT}",
        "region": "{env:GOOGLE_VERTEX_REGION}"
      }
    },
    "google-vertex": {
      "name": "Google Vertex AI",
      "options": {
        "project": "{env:GOOGLE_VERTEX_PROJECT}",
        "region": "{env:GOOGLE_VERTEX_LOCATION}"
      }
    }
  }
}
EOF

# Set proper permissions for the user config
chown -R user:user /home/user/.config/opencode
chmod -R 755 /home/user/.config/opencode

# Set up Google Vertex environment variables for all users
echo '# Google Vertex AI environment variables for OpenCode' >> /etc/bash.bashrc
echo 'export GOOGLE_VERTEX_PROJECT="${GOOGLE_VERTEX_PROJECT:-}"' >> /etc/bash.bashrc
echo 'export GOOGLE_VERTEX_LOCATION="${GOOGLE_VERTEX_LOCATION:-global}"' >> /etc/bash.bashrc
echo '' >> /etc/bash.bashrc

# Also add to /etc/profile for non-interactive shells
echo '# Google Vertex AI environment variables for OpenCode' >> /etc/profile
echo 'export GOOGLE_VERTEX_PROJECT="${GOOGLE_VERTEX_PROJECT:-}"' >> /etc/profile
echo 'export GOOGLE_VERTEX_LOCATION="${GOOGLE_VERTEX_LOCATION:-global}"' >> /etc/profile
echo '' >> /etc/profile

# Copy mounted credentials to user's gcloud config if they exist
if [ -f "/tmp/gcloud-creds.json" ]; then
    echo "🔑 Setting up Google Cloud credentials for user..."
    mkdir -p /home/user/.config/gcloud
    cp /tmp/gcloud-creds.json /home/user/.config/gcloud/application_default_credentials.json
    chown user:user /home/user/.config/gcloud/application_default_credentials.json
    chmod 600 /home/user/.config/gcloud/application_default_credentials.json
fi

# Install Midnight Compact VS Code extension
echo "🔧 Installing Midnight Compact VS Code extension..."
sudo -u user /opt/code-oss/bin/codeoss-cloudworkstations --install-extension midnight-network.midnight-compact --force 2>/dev/null || echo "Midnight Compact extension installation attempted"

echo "✅ Midnight Vibe Platform initialization complete!"
echo "🌐 Access services:"
echo "   - Code OSS (VS Code): http://[HOSTNAME]:80"
echo "   - PostgreSQL: [HOSTNAME]:5432"
echo "   - Proof Server: http://[HOSTNAME]:8081"
echo "   - Midnight Node: http://[HOSTNAME]:9933"
echo "   - OpenCode AI: podman exec -it \$(hostname) bash -c 'export PATH=/root/.opencode/bin:\$PATH && opencode'"