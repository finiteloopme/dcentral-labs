#!/bin/bash
# Simple startup script for local development
# Bypasses the complex Cloud Workstations initialization

echo "Starting Midnight Workstation (Local Development Mode)"
echo "=================================================="
echo ""
echo "Running as: $(whoami) (UID: $(id -u), GID: $(id -g))"
echo ""

# Use /tmp for writable directories since /home/user might not be writable
export HOME=/tmp/user-home
mkdir -p $HOME

# Create necessary directories in temp space
mkdir -p $HOME/.codeoss-cloudworkstations/data/Machine
mkdir -p $HOME/.codeoss-cloudworkstations/extensions
mkdir -p $HOME/workspace/projects
mkdir -p $HOME/workspace/templates

# Copy templates if not present
if [ ! -d $HOME/workspace/templates/basic-token ]; then
    cp -r /opt/templates/* $HOME/workspace/templates/ 2>/dev/null || true
fi

# Start Code OSS or fallback web server
echo "Starting web IDE service..."

# Check if Code OSS binary exists and is executable
CODE_OSS_BIN="/opt/code-oss/bin/codeoss-cloudworkstations"
if [ -x "$CODE_OSS_BIN" ]; then
    echo "Starting Code OSS on port 80..."
    $CODE_OSS_BIN \
        --port 80 \
        --host 0.0.0.0 \
        --without-connection-token \
        --disable-telemetry \
        --user-data-dir $HOME/.codeoss-cloudworkstations/data \
        --extensions-dir $HOME/.codeoss-cloudworkstations/extensions \
        > /tmp/code-oss.log 2>&1 &
    
    CODE_PID=$!
    echo "Code OSS started with PID: $CODE_PID"
else
    echo "Warning: Code OSS binary not found or not executable"
    echo "Starting fallback web server for testing..."
    
    # Create a simple index page
    mkdir -p $HOME/www
    cat > $HOME/www/index.html << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>Midnight Workstation</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; }
        h1 { color: #333; }
        .status { padding: 10px; background: #f0f0f0; border-radius: 5px; margin: 10px 0; }
        .ok { color: green; }
        .warn { color: orange; }
    </style>
</head>
<body>
    <h1>🌙 Midnight Development Workstation</h1>
    <div class="status">
        <h2>Status</h2>
        <p class="warn">⚠️ Code OSS not available - Running in fallback mode</p>
        <p class="ok">✓ Container is running</p>
        <p>Proof Server: <a href="http://localhost:8081">http://localhost:8081</a></p>
    </div>
    <div class="status">
        <h2>Troubleshooting</h2>
        <p>To debug, run:</p>
        <pre>docker exec -it midnight-local /bin/bash</pre>
        <p>Then check logs:</p>
        <pre>cat /tmp/code-oss.log</pre>
    </div>
</body>
</html>
EOF
    
    # Start Python HTTP server as fallback
    cd $HOME/www
    python3 -m http.server 8080 > /tmp/web-server.log 2>&1 &
    echo "Fallback web server started on port 8080"
fi

# Start proof server
echo "Starting Midnight Proof Server on port 8081..."
cd /opt/midnight/proof-server
PORT=8081 nohup npm start > /tmp/proof-server.log 2>&1 &

# Set up OpenCode TUI configuration
echo "Setting up OpenCode TUI..."
mkdir -p $HOME/.config/opencode

# Ensure OpenCode can find its config
export OPENCODE_CONFIG_DIR=$HOME/.config/opencode

# Check if OpenCode is installed (check the real npm-installed version)
if [ -x "/usr/bin/opencode" ]; then
    echo "✓ OpenCode TUI is installed (version $(/usr/bin/opencode --version 2>/dev/null || echo 'unknown'))"
else
    echo "⚠ OpenCode TUI not found - installing..."
    npm install -g opencode-ai@latest 2>/dev/null || echo "Failed to install OpenCode"
fi

# Wait a bit for services to start
echo ""
echo "Waiting for services to start..."
sleep 5

# Check if Code OSS is actually running
echo ""
echo "Checking services..."
if ps aux | grep -v grep | grep -q codeoss-cloudworkstations; then
    echo "✓ Code OSS is running"
else
    echo "✗ Code OSS is not running"
    echo "Code OSS log (last 20 lines):"
    tail -20 /tmp/code-oss.log
fi

if ps aux | grep -v grep | grep -q "npm.*start"; then
    echo "✓ Proof server is running"
else
    echo "✗ Proof server is not running"
    echo "Proof server log (last 10 lines):"
    tail -10 /tmp/proof-server.log
fi

# Check if ports are listening
echo ""
echo "Checking ports..."
netstat -tuln 2>/dev/null | grep -E ":(8080|8081)" || echo "No ports listening (netstat might not be available)"

echo ""
echo "Services available:"
echo "  • Code OSS IDE: http://localhost:8080"
echo "  • Proof Server: http://localhost:8081"
echo ""
echo "CLI Tools available in terminal:"
echo "  • opencode     - AI coding assistant TUI (set ANTHROPIC_API_KEY first)"
echo "  • midnight     - Midnight CLI tool"
echo "  • compactc     - Compact language compiler"
echo ""
echo "To use OpenCode TUI:"
echo "  1. Open terminal in Code OSS (Terminal > New Terminal)"
echo "  2. Set your API key: export ANTHROPIC_API_KEY='your-key-here'"
echo "  3. Run: opencode"
echo "  4. The TUI interface will launch"
echo ""
echo "Logs:"
echo "  • Code OSS: /tmp/code-oss.log"
echo "  • Proof Server: /tmp/proof-server.log"
echo ""
echo "Press Ctrl+C to stop"

# Keep container running and show logs
tail -f /tmp/code-oss.log /tmp/proof-server.log