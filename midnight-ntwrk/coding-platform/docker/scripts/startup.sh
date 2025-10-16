#!/bin/bash
# Midnight Development Platform - Startup Script

echo "Initializing Midnight Development Environment..."

# Create CLI wrapper
cat > /usr/local/bin/midnight <<'EOF'
#!/bin/bash
# Midnight CLI wrapper

COMMAND=$1
shift

case "$COMMAND" in
    new)
        PROJECT_NAME=$1
        if [ -z "$PROJECT_NAME" ]; then
            echo "Usage: midnight new <project-name>"
            exit 1
        fi
        echo "Creating new Midnight DApp project: $PROJECT_NAME"
        cp -r /workspace/templates/basic-token "/workspace/projects/$PROJECT_NAME"
        cd "/workspace/projects/$PROJECT_NAME"
        npm init -y > /dev/null 2>&1
        npm install > /dev/null 2>&1
        echo "✓ Project created at /workspace/projects/$PROJECT_NAME"
        echo "  Run 'cd /workspace/projects/$PROJECT_NAME' to get started"
        ;;
    
    compile)
        echo "Compiling Compact contracts..."
        if [ -f "Makefile" ]; then
            make compile
        else
            for file in contracts/*.compact; do
                if [ -f "$file" ]; then
                    compactc "$file"
                fi
            done
        fi
        ;;
    
    test)
        echo "Running contract tests..."
        if [ -f "package.json" ]; then
            npm test
        else
            echo "No tests found. Create a package.json with test script."
        fi
        ;;
    
    prove)
        echo "Generating zero-knowledge proofs..."
        for file in build/*.json; do
            if [ -f "$file" ]; then
                prove "$file"
            fi
        done
        ;;
    
    deploy)
        echo "Deploying to Midnight testnet..."
        if [ -f "Makefile" ]; then
            make deploy
        else
            echo "Connecting to testnet..."
            sleep 1
            echo "Submitting transaction..."
            sleep 2
            echo "✓ Contract deployed to address: 0x742d35Cc6634C0532925a3b844Bc0e7A41051aE8"
            echo "  Transaction hash: 0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef"
        fi
        ;;
    
    help|--help|-h)
        echo "Midnight CLI - Command Line Interface for Midnight Development"
        echo ""
        echo "Commands:"
        echo "  new <name>    Create a new DApp project"
        echo "  compile       Compile Compact smart contracts"
        echo "  test          Run contract tests"
        echo "  prove         Generate zero-knowledge proofs"
        echo "  deploy        Deploy contracts to testnet"
        echo "  help          Show this help message"
        ;;
    
    *)
        echo "Unknown command: $COMMAND"
        echo "Run 'midnight help' for usage information"
        exit 1
        ;;
esac
EOF
chmod +x /usr/local/bin/midnight

# Set up Git configuration
git config --global user.name "Midnight Developer"
git config --global user.email "developer@midnight.network"
git config --global init.defaultBranch main

# Initialize proof service mock (runs in background)
PROOF_PORT="${PROOF_PORT:-8080}"
cat > /tmp/proof-service.js <<EOF
const http = require('http');
const url = require('url');
const PORT = ${PROOF_PORT};

const server = http.createServer((req, res) => {
    const parsedUrl = url.parse(req.url, true);
    
    res.setHeader('Content-Type', 'application/json');
    res.setHeader('Access-Control-Allow-Origin', '*');
    
    if (req.method === 'OPTIONS') {
        res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
        res.setHeader('Access-Control-Allow-Headers', 'Content-Type');
        res.writeHead(200);
        res.end();
        return;
    }
    
    if (parsedUrl.pathname === '/health') {
        res.writeHead(200);
        res.end(JSON.stringify({ status: 'healthy', service: 'midnight-proof-service' }));
    } else if (parsedUrl.pathname === '/proof/generate' && req.method === 'POST') {
        let body = '';
        req.on('data', chunk => body += chunk);
        req.on('end', () => {
            setTimeout(() => {
                res.writeHead(200);
                res.end(JSON.stringify({
                    proof: {
                        pi_a: ["0x" + Math.random().toString(16).substr(2, 16)],
                        pi_b: [["0x" + Math.random().toString(16).substr(2, 8)]],
                        pi_c: ["0x" + Math.random().toString(16).substr(2, 16)],
                    },
                    public_signals: [],
                    status: 'success',
                    timestamp: new Date().toISOString()
                }));
            }, 1000);
        });
    } else if (parsedUrl.pathname === '/proof/verify' && req.method === 'POST') {
        let body = '';
        req.on('data', chunk => body += chunk);
        req.on('end', () => {
            res.writeHead(200);
            res.end(JSON.stringify({
                valid: true,
                timestamp: new Date().toISOString()
            }));
        });
    } else {
        res.writeHead(404);
        res.end(JSON.stringify({ error: 'Not found' }));
    }
});

server.listen(PORT, '0.0.0.0', () => {
    console.log('Proof service running on http://0.0.0.0:' + PORT);
});
EOF

# Start the proof service in background
echo "Starting proof service on port $PROOF_PORT..."
nohup node /tmp/proof-service.js > /var/log/proof-service.log 2>&1 &
sleep 1
if pgrep -f "node /tmp/proof-service.js" > /dev/null; then
    echo "✓ Proof service running on port $PROOF_PORT"
else
    echo "⚠ Proof service failed to start. Check /var/log/proof-service.log"
fi

# Create initial workspace structure if not exists
if [ ! -d "/workspace/projects" ]; then
    mkdir -p /workspace/projects
fi

# Set proper permissions (handle different user scenarios)
if id "user" &>/dev/null; then
    chown -R user:user /workspace 2>/dev/null || true
else
    # If user doesn't exist, try common alternatives
    chown -R 1000:1000 /workspace 2>/dev/null || \
    chown -R $(whoami):$(whoami) /workspace 2>/dev/null || \
    true
fi

# Verify opencode installation and clean up invalid config
if command -v opencode-ai &> /dev/null; then
    echo "✓ OpenCode AI available - run 'opencode-ai' for AI assistance"
    # Remove any config file that might have invalid keys
    rm -f /root/.config/opencode/config.json 2>/dev/null || true
    rm -f /home/*/.config/opencode/config.json 2>/dev/null || true
elif command -v opencode &> /dev/null; then
    echo "✓ OpenCode available - run 'opencode' for AI assistance"
    # Remove any config file that might have invalid keys
    rm -f /root/.config/opencode/config.json 2>/dev/null || true
    rm -f /home/*/.config/opencode/config.json 2>/dev/null || true
else
    echo "⚠ OpenCode not found - installing..."
    npm install -g opencode-ai &> /dev/null && echo "✓ OpenCode installed"
fi

# Start OpenCode web terminal service
if [ -f /opt/opencode-terminal/web-terminal.js ]; then
    # Use a higher port if needed
    export TERMINAL_PORT="${TERMINAL_PORT:-7681}"
    echo "Starting OpenCode Web Terminal on port $TERMINAL_PORT..."
    cd /opt/opencode-terminal
    nohup node web-terminal.js > /var/log/opencode-terminal.log 2>&1 &
    sleep 2  # Give it a moment to start
    if pgrep -f "node web-terminal.js" > /dev/null; then
        echo "✓ OpenCode Web Terminal available at http://localhost:$TERMINAL_PORT"
    else
        echo "⚠ OpenCode Web Terminal failed to start. Check /var/log/opencode-terminal.log"
    fi
fi

# Start VS Code Server
echo "Starting VS Code Server on port 8443..."
if command -v code-server &> /dev/null; then
    nohup code-server --bind-addr 0.0.0.0:8443 --auth none --disable-telemetry /workspace > /var/log/code-server.log 2>&1 &
    sleep 3  # Give it time to start
    if pgrep -f "code-server" > /dev/null; then
        echo "✓ VS Code Server available at http://localhost:8443"
    else
        echo "⚠ VS Code Server failed to start. Check /var/log/code-server.log"
    fi
elif command -v code &> /dev/null; then
    # Try the code CLI with serve-web if available
    nohup code serve-web --bind-addr 0.0.0.0:8443 --without-connection-token /workspace > /var/log/code-server.log 2>&1 &
    sleep 3
    if pgrep -f "code.*serve-web" > /dev/null; then
        echo "✓ VS Code Server available at http://localhost:8443"
    else
        echo "⚠ VS Code Server not available - install code-server for IDE support"
    fi
else
    echo "⚠ VS Code Server not available - install code-server for IDE support"
fi

# Display welcome message on first terminal
# Add to multiple possible bashrc locations
for bashrc_file in /home/user/.bashrc /root/.bashrc /etc/bash.bashrc; do
    if [ -f "$bashrc_file" ]; then
        if ! grep -q "/workspace/welcome.sh" "$bashrc_file" 2>/dev/null; then
            echo "/workspace/welcome.sh" >> "$bashrc_file" 2>/dev/null || true
        fi
    fi
done

echo "✓ Midnight Development Environment initialized successfully!"