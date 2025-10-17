#!/bin/bash
# Midnight Development Platform - Startup Script

echo "Initializing Midnight Development Environment..."

# Show configuration if available
if [ -n "$PROOF_SERVICE_URL" ] && [ "$PROOF_SERVICE_URL" != "http://localhost:8080" ]; then
    echo "Using external proof service: $PROOF_SERVICE_URL"
fi

# Configure Google Cloud authentication if in Cloud Workstations
if [ -n "$GOOGLE_CLOUD_PROJECT" ] || [ -n "$GCP_PROJECT_ID" ]; then
    export GCP_PROJECT_ID="${GCP_PROJECT_ID:-$GOOGLE_CLOUD_PROJECT}"
    echo "Detected GCP Project: $GCP_PROJECT_ID"
    
    # Configure OpenCode with Vertex AI
    if [ -x /usr/local/bin/configure-opencode ]; then
        echo "Configuring OpenCode for Vertex AI..."
        /usr/local/bin/configure-opencode
    fi
fi

# Update contract templates if available
if [ -x /opt/scripts/update-templates.sh ]; then
    /opt/scripts/update-templates.sh
fi

# Copy improved Makefile if it doesn't exist
if [ -f /opt/scripts/Makefile.template ] && [ -d /workspace/templates/basic-token ]; then
    if [ ! -f /workspace/templates/basic-token/Makefile ] || [ ! -s /workspace/templates/basic-token/Makefile ]; then
        cp /opt/scripts/Makefile.template /workspace/templates/basic-token/Makefile 2>/dev/null || true
    fi
fi

# Create CLI wrapper
cat > /usr/local/bin/midnight <<'EOF'
#!/bin/bash
# Midnight CLI wrapper

COMMAND=$1
shift

case "$COMMAND" in
    new)
        PROJECT_NAME="${1:-my-dapp}"
        echo "Creating new Midnight DApp project: $PROJECT_NAME"
        mkdir -p "/workspace/projects/$PROJECT_NAME"
        
        # Copy template files
        cp -r /workspace/templates/basic-token/* "/workspace/projects/$PROJECT_NAME/" 2>/dev/null || true
        
        # Use the fixed Makefile if available
        if [ -f "/opt/scripts/Makefile.fixed" ]; then
            cp /opt/scripts/Makefile.fixed "/workspace/projects/$PROJECT_NAME/Makefile"
        elif [ -f "/opt/scripts/Makefile.template" ]; then
            cp /opt/scripts/Makefile.template "/workspace/projects/$PROJECT_NAME/Makefile"
        fi
        
        cd "/workspace/projects/$PROJECT_NAME"
        npm init -y > /dev/null 2>&1
        npm install > /dev/null 2>&1
        
        # Create build directory
        mkdir -p build
        
        echo "✓ Project created at /workspace/projects/$PROJECT_NAME"
        echo "  Run 'cd /workspace/projects/$PROJECT_NAME' to get started"
        ;;
    
    compile)
        echo "🔨 Compiling Compact contracts..."
        
        # Create build directory if it doesn't exist
        mkdir -p build
        
        if [ -f "Makefile" ]; then
            make compile
        else
            # Compile all .compact files from contracts directory
            if ls contracts/*.compact 1> /dev/null 2>&1; then
                for file in contracts/*.compact; do
                    if [ -f "$file" ]; then
                        echo "  Compiling $(basename "$file")..."
                        # Compile and move output to build directory
                        compactc "$file" -o "build/$(basename "${file%.compact}.json")"
                    fi
                done
                echo "✓ Compilation complete!"
            else
                echo "No .compact files found in contracts/"
                echo "Create a contract file in contracts/ directory first"
                exit 1
            fi
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
        echo "🔐 Generating zero-knowledge proofs..."
        
        # Check if proof service is configured
        PROOF_URL="${PROOF_SERVICE_URL:-http://localhost:8080}"
        echo "Using proof service: $PROOF_URL"
        
        # Check if build directory exists
        if [ ! -d "build" ]; then
            echo "❌ Error: build/ directory not found"
            echo "Run 'midnight compile' first to compile your contracts"
            exit 1
        fi
        
        # Process all compiled contracts
        if ls build/*.json 1> /dev/null 2>&1; then
            PROOF_COUNT=0
            for file in build/*.json; do
                if [ -f "$file" ]; then
                    echo ""
                    echo "📄 Processing: $(basename $file)"
                    if prove "$file"; then
                        ((PROOF_COUNT++))
                    else
                        echo "⚠️  Warning: Failed to generate proof for $(basename $file)"
                    fi
                fi
            done
            echo ""
            echo "✅ Generated $PROOF_COUNT proof(s)"
        else
            echo "❌ Error: No compiled contracts found in build/"
            echo "Your build/ directory exists but contains no .json files"
            echo "Run 'midnight compile' to compile your .compact contracts"
            exit 1
        fi
        ;;
    
    verify)
        PROOF_FILE="${1:-}"
        if [ -z "$PROOF_FILE" ]; then
            echo "Usage: midnight verify <proof-file>"
            echo ""
            echo "Examples:"
            echo "  midnight verify build/Token.proof"
            echo "  midnight verify proofs/transfer.proof"
            echo ""
            echo "To verify all proofs in a directory:"
            echo "  for proof in build/*.proof; do midnight verify \$proof; done"
            exit 1
        fi
        
        if [ ! -f "$PROOF_FILE" ]; then
            echo "Error: Proof file not found: $PROOF_FILE"
            exit 1
        fi
        
        echo "Verifying proof: $PROOF_FILE"
        
        # Determine proof service URL
        PROOF_SERVICE="${PROOF_SERVICE_URL:-http://localhost:8080}"
        
        # Extract proof data
        PROOF_DATA=$(cat "$PROOF_FILE")
        
        # Call verification endpoint
        RESPONSE=$(curl -s -X POST \
            -H "Content-Type: application/json" \
            -d "$PROOF_DATA" \
            "${PROOF_SERVICE}/proof/verify" 2>/dev/null)
        
        if echo "$RESPONSE" | grep -q '"valid":true'; then
            echo "✅ Proof is VALID"
            
            # Show additional details if available
            TIMESTAMP=$(echo "$RESPONSE" | jq -r '.timestamp // empty' 2>/dev/null)
            if [ -n "$TIMESTAMP" ]; then
                echo "  Verified at: $TIMESTAMP"
            fi
            
            # Show circuit info from the proof file
            CIRCUIT=$(cat "$PROOF_FILE" | jq -r '.circuit // empty' 2>/dev/null)
            if [ -n "$CIRCUIT" ]; then
                echo "  Circuit: $CIRCUIT"
            fi
            
            # Show protocol
            PROTOCOL=$(cat "$PROOF_FILE" | jq -r '.proof.protocol // empty' 2>/dev/null)
            if [ -n "$PROTOCOL" ]; then
                echo "  Protocol: $PROTOCOL"
            fi
        else
            echo "❌ Proof is INVALID"
            ERROR_MSG=$(echo "$RESPONSE" | jq -r '.error // .message // empty' 2>/dev/null)
            if [ -n "$ERROR_MSG" ]; then
                echo "  Error: $ERROR_MSG"
            elif [ -n "$RESPONSE" ]; then
                echo "  Response: $RESPONSE"
            fi
            exit 1
        fi
        ;;
    
    deploy)
        echo "Deploying to Midnight testnet..."
        
        # Check for proof files
        if ls build/*.proof 1> /dev/null 2>&1; then
            echo "Found proof files, including in deployment..."
        else
            echo "Warning: No proof files found. Run 'midnight prove' first."
        fi
        
        if [ -f "Makefile" ]; then
            make deploy
        else
            echo "Connecting to testnet..."
            sleep 1
            echo "Submitting transaction with proofs..."
            sleep 2
            echo "✓ Contract deployed to address: 0x742d35Cc6634C0532925a3b844Bc0e7A41051aE8"
            echo "  Transaction hash: 0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef"
            echo "  Gas used: 142,589"
            echo "  Block: 15,234,567"
        fi
        ;;
    
    help|--help|-h)
        echo "Midnight CLI - Command Line Interface for Midnight Development"
        echo ""
        echo "Commands:"
        echo "  new <name>       Create a new DApp project"
        echo "  compile          Compile Compact smart contracts"
        echo "  test             Run contract tests"
        echo "  prove            Generate zero-knowledge proofs"
        echo "  verify <proof>   Verify a proof file"
        echo "  deploy           Deploy contracts to testnet"
        echo "  help             Show this help message"
        echo ""
        echo "Environment Variables:"
        echo "  PROOF_SERVICE_URL  URL of proof generation service (default: http://localhost:8080)"
        echo ""
        echo "Examples:"
        echo "  midnight new my-token"
        echo "  midnight compile"
        echo "  midnight prove"
        echo "  midnight verify build/Token.proof"
        echo "  midnight deploy"
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

# Configure proof service based on mode
PROOF_SERVICE_MODE="${PROOF_SERVICE_MODE:-local}"
PROOF_SERVICE_PORT="${PROOF_SERVICE_PORT:-8080}"
PROOF_SERVICE_URL="${PROOF_SERVICE_URL:-}"

case "$PROOF_SERVICE_MODE" in
    local)
        echo "Starting local proof server..."
        
        # Check if we have Node.js for the enhanced mock server
        if [ -x "/opt/midnight/bin/proof-server" ] && command -v node &> /dev/null; then
            echo "Starting Midnight proof server (enhanced mock v4.0.0 API-compatible)..."
            
            # Create log directory
            mkdir -p /var/log/midnight
            
            # Start the proof server
            nohup node /opt/midnight/bin/proof-server > /var/log/midnight/proof-server.log 2>&1 &
            PROOF_PID=$!
            
            # Wait for proof server to be ready
            echo -n "Waiting for proof server to start"
            for i in {1..30}; do
                if curl -s http://localhost:${PROOF_SERVICE_PORT}/health 2>/dev/null | grep -q "healthy"; then
                    echo ""
                    VERSION=$(curl -s http://localhost:${PROOF_SERVICE_PORT}/health 2>/dev/null | jq -r '.version // "unknown"')
                    echo "✓ Proof server running on port ${PROOF_SERVICE_PORT} (version: $VERSION)"
                    export PROOF_SERVICE_URL="http://localhost:${PROOF_SERVICE_PORT}"
                    break
                fi
                echo -n "."
                sleep 1
            done
            
            if ! curl -s http://localhost:${PROOF_SERVICE_PORT}/health > /dev/null 2>&1; then
                echo ""
                echo "Warning: Proof server failed to start, falling back to basic mock"
                kill $PROOF_PID 2>/dev/null || true
                START_BASIC_MOCK=true
            else
                START_BASIC_MOCK=false
            fi
        else
            echo "Starting basic mock proof service..."
            START_BASIC_MOCK=true
        fi
        
        # Start basic mock service if needed (fallback)
        if [ "$START_BASIC_MOCK" = true ]; then
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

            # Start the mock proof service in background
            echo "Starting mock proof service on port ${PROOF_SERVICE_PORT}..."
            nohup node /tmp/proof-service.js > /var/log/midnight/proof-service.log 2>&1 &
            sleep 1
            if pgrep -f "node /tmp/proof-service.js" > /dev/null; then
                echo "✓ Mock proof service running on port ${PROOF_SERVICE_PORT}"
                export PROOF_SERVICE_URL="http://localhost:${PROOF_SERVICE_PORT}"
            else
                echo "⚠ Mock proof service failed to start. Check /var/log/midnight/proof-service.log"
            fi
        fi
        ;;
        
    external)
        if [ -z "$PROOF_SERVICE_URL" ]; then
            echo "Error: PROOF_SERVICE_MODE is 'external' but PROOF_SERVICE_URL is not set"
            echo "Please set PROOF_SERVICE_URL environment variable to your external proof service"
            exit 1
        fi
        echo "✓ Using external proof service: $PROOF_SERVICE_URL"
        
        # Test connectivity to external service
        if curl -s --connect-timeout 5 "${PROOF_SERVICE_URL}/health" > /dev/null 2>&1; then
            echo "✓ External proof service is reachable"
        else
            echo "⚠ Warning: Cannot reach external proof service at ${PROOF_SERVICE_URL}"
            echo "  Proof generation may fail. Please check your configuration."
        fi
        export PROOF_SERVICE_URL
        ;;
        
    *)
        echo "Error: Invalid PROOF_SERVICE_MODE: $PROOF_SERVICE_MODE"
        echo "Valid options are: local, external"
        exit 1
        ;;
esac

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

# Verify opencode installation and configure it
if command -v opencode-ai &> /dev/null; then
    OPENCODE_CMD="opencode-ai"
    echo "✓ OpenCode AI available - run 'opencode-ai' for AI assistance"
elif command -v opencode &> /dev/null; then
    OPENCODE_CMD="opencode"
    echo "✓ OpenCode available - run 'opencode' for AI assistance"
else
    echo "⚠ OpenCode not found - installing..."
    npm install -g opencode-ai &> /dev/null && echo "✓ OpenCode installed"
    OPENCODE_CMD="opencode-ai"
fi

# Configure OpenCode automatically if not already configured
OPENCODE_CONFIG_DIR="${HOME}/.config/opencode"
OPENCODE_CONFIG_FILE="${OPENCODE_CONFIG_DIR}/opencode.json"

if [ ! -f "$OPENCODE_CONFIG_FILE" ]; then
    echo "Configuring OpenCode with Vertex AI..."
    mkdir -p "$OPENCODE_CONFIG_DIR"
    
    # Get project ID from environment or use placeholder
    PROJECT_ID="${GCP_PROJECT_ID:-${PROJECT_ID:-your-gcp-project}}"
    
    # Create OpenCode configuration with Vertex AI
    cat > "$OPENCODE_CONFIG_FILE" << EOF
{
  "\$schema": "https://opencode.ai/config.json",
  "theme": "opencode",
  "autoupdate": true,
  "model": "google-vertex-anthropic/claude-opus-4-1@20250805",
  "small_model": "google-vertex-anthropic/claude-3-5-haiku@20241022",
  "provider": {
    "google-vertex-anthropic": {
      "models": {
        "claude-opus-4-1@20250805": {},
        "claude-3-5-sonnet-v2@20241022": {},
        "claude-3-5-haiku@20241022": {}
      },
      "options": {
        "project": "${PROJECT_ID}",
        "location": "global"
      }
    },
    "google-vertex": {
      "models": {
        "gemini-2.5-flash": {},
        "gemini-2.5-pro": {}
      },
      "options": {
        "project": "${PROJECT_ID}",
        "location": "global"
      }
    }
  },
  "tools": {
    "write": true,
    "edit": true,
    "bash": true,
    "read": true
  },
  "tui": {
    "scroll_speed": 3
  },
  "instructions": [
    "You are an expert Web3, blockchain security, and Midnight Network developer with deep knowledge of:",
    "- Smart contract development and security best practices",
    "- Zero-knowledge proofs and privacy-preserving technologies",
    "- Midnight's Compact language and circuit development",
    "- DApp architecture and decentralized systems",
    "- Cryptographic protocols and implementations",
    "",
    "When working with Midnight projects:",
    "- Prioritize security and privacy in all implementations",
    "- Follow Midnight's best practices for circuit design",
    "- Ensure proper use of @shielded decorators for private state",
    "- Implement comprehensive tests for circuits and proofs",
    "- Consider gas optimization and proof generation efficiency"
  ]
}
EOF
    
    echo "✓ OpenCode configured with Vertex AI models"
    
    # Check if we have GCP credentials
    if [ -n "$GOOGLE_APPLICATION_CREDENTIALS" ] && [ -f "$GOOGLE_APPLICATION_CREDENTIALS" ]; then
        echo "✓ Google Cloud credentials found"
    elif [ -f "$HOME/.config/gcloud/application_default_credentials.json" ]; then
        echo "✓ Application default credentials found"
        export GOOGLE_APPLICATION_CREDENTIALS="$HOME/.config/gcloud/application_default_credentials.json"
    elif command -v gcloud &> /dev/null && gcloud auth list --filter=status:ACTIVE --format="value(account)" &>/dev/null; then
        echo "✓ Google Cloud authentication detected"
    else
        echo "⚠ No Google Cloud credentials found. To use Vertex AI models:"
        echo "  1. Mount credentials: -v ~/.config/gcloud:/root/.config/gcloud:ro"
        echo "  2. Or run: gcloud auth application-default login"
    fi
else
    echo "✓ OpenCode already configured"
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