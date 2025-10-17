# Start with base Cloud Workstations image
FROM us-central1-docker.pkg.dev/cloud-workstations-images/predefined/code-oss:latest

# Note: The Midnight proof server will be integrated once the official image structure is confirmed
# For now, we'll use a mock service with the same API interface

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive
ENV NODE_VERSION=20

# Update and install essential tools
RUN apt-get update && apt-get install -y \
    curl \
    wget \
    git \
    build-essential \
    python3 \
    python3-pip \
    jq \
    zip \
    unzip \
    vim \
    nano \
    htop \
    net-tools \
    iputils-ping \
    && rm -rf /var/lib/apt/lists/*

# Install Node.js and npm
RUN curl -fsSL https://deb.nodesource.com/setup_${NODE_VERSION}.x | bash - \
    && apt-get install -y nodejs \
    && npm install -g npm@latest

# Install development tools
RUN npm install -g \
    typescript \
    ts-node \
    nodemon \
    prettier \
    eslint \
    http-server \
    json-server

# Install Google Cloud SDK for Vertex AI authentication
# The base image may already have gcloud, so check first
RUN if ! command -v gcloud &> /dev/null; then \
        echo "Installing Google Cloud SDK..." && \
        # Use the quick install method \
        curl -sSL https://sdk.cloud.google.com | bash -s -- --disable-prompts --install-dir=/opt && \
        ln -s /opt/google-cloud-sdk/bin/gcloud /usr/local/bin/gcloud && \
        ln -s /opt/google-cloud-sdk/bin/gsutil /usr/local/bin/gsutil; \
    else \
        echo "Google Cloud SDK already installed at: $(which gcloud)"; \
    fi && \
    # Verify installation \
    gcloud version

# Install OpenCode AI assistant with Vertex AI support
RUN npm install -g opencode-ai @ai-sdk/google-vertex

# Install code-server for VS Code in browser
RUN curl -fsSL https://code-server.dev/install.sh | sh

# Install packages for web terminal server
RUN npm install -g \
    express \
    express-ws \
    node-pty \
    @xterm/xterm

# Create Midnight tools directory
RUN mkdir -p /opt/midnight/bin && \
    mkdir -p /opt/midnight/lib && \
    mkdir -p /opt/midnight/config && \
    mkdir -p /var/log/midnight

# Create mock Midnight compiler script
RUN cat > /opt/midnight/bin/compactc <<'EOF'
#!/bin/bash
# Mock Midnight Compact compiler for MVP

echo "Midnight Compact Compiler v0.1.0-mvp"
echo "======================================="

if [ $# -eq 0 ]; then
    echo "Usage: compactc [options] <input-file>"
    echo "Options:"
    echo "  -o <output>  Specify output file"
    echo "  -O           Enable optimizations"
    echo "  --abi        Generate ABI file"
    echo "  --bytecode   Generate bytecode file"
    exit 1
fi

# Parse command line arguments
OUTPUT_FILE=""
INPUT_FILE=""
while [[ $# -gt 0 ]]; do
    case $1 in
        -o|--output)
            OUTPUT_FILE="$2"
            shift 2
            ;;
        -O|--optimize)
            # Optimization flag (ignored in mock)
            shift
            ;;
        --abi|--bytecode)
            # Additional output flags (ignored in mock)
            shift
            ;;
        *)
            INPUT_FILE="$1"
            shift
            ;;
    esac
done

if [ -z "$INPUT_FILE" ]; then
    echo "Error: No input file specified"
    exit 1
fi

if [ ! -f "$INPUT_FILE" ]; then
    echo "Error: Input file '$INPUT_FILE' not found"
    exit 1
fi

# If no output file specified, use default
if [ -z "$OUTPUT_FILE" ]; then
    OUTPUT_FILE="${INPUT_FILE%.compact}.json"
fi

# Create output directory if needed
OUTPUT_DIR=$(dirname "$OUTPUT_FILE")
if [ ! -d "$OUTPUT_DIR" ]; then
    mkdir -p "$OUTPUT_DIR"
fi

echo "Compiling: $INPUT_FILE"
echo "Parsing contract..."
sleep 1
echo "Type checking..."
sleep 0.5
echo "Generating bytecode..."
sleep 0.5
echo "Optimizing..."
sleep 0.5

# Generate mock output
cat > "$OUTPUT_FILE" <<EOJSON
{
  "contract": "$(basename $INPUT_FILE .compact)",
  "bytecode": "0x608060405234801561001057600080fd5b50610150806100206000396000f3fe",
  "abi": [
    {
      "type": "constructor",
      "inputs": [{"name": "_initialSupply", "type": "uint256"}]
    },
    {
      "type": "function",
      "name": "transfer",
      "inputs": [
        {"name": "to", "type": "address"},
        {"name": "amount", "type": "uint256"}
      ],
      "outputs": [{"name": "", "type": "bool"}]
    },
    {
      "type": "function",
      "name": "balanceOf",
      "inputs": [{"name": "account", "type": "address"}],
      "outputs": [{"name": "", "type": "uint256"}]
    }
  ],
  "metadata": {
    "compiler": "compactc-0.1.0-mvp",
    "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  }
}
EOJSON

echo "✓ Compilation successful!"
echo "Output written to: $OUTPUT_FILE"
EOF
RUN chmod +x /opt/midnight/bin/compactc

# Create mock proof generator
RUN cat > /opt/midnight/bin/prove <<'EOF'
#!/bin/bash
# Midnight proof generator - calls configured proof service

echo "Midnight Proof Generator v0.2.0"
echo "================================"

# Parse command line arguments
OUTPUT_FILE=""
PROOF_TYPE="groth16"
VERIFY_AFTER=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -o|--output)
            OUTPUT_FILE="$2"
            shift 2
            ;;
        -t|--type)
            PROOF_TYPE="$2"
            shift 2
            ;;
        --verify)
            VERIFY_AFTER=true
            shift
            ;;
        -h|--help)
            echo "Usage: prove [options] <input-file>"
            echo "Options:"
            echo "  -o, --output <file>  Specify output file"
            echo "  -t, --type <type>    Proof type (groth16, plonk, stark)"
            echo "  --verify             Verify proof after generation"
            echo "  -h, --help           Show this help message"
            exit 0
            ;;
        *)
            INPUT_FILE="$1"
            shift
            ;;
    esac
done

# Check if input file was provided
if [ -z "$INPUT_FILE" ]; then
    echo "Error: No input file specified"
    echo "Usage: prove [options] <input-file>"
    exit 1
fi

# Check if input file exists
if [ ! -f "$INPUT_FILE" ]; then
    echo "Error: Input file not found: $INPUT_FILE"
    exit 1
fi

# Set default output file if not specified
if [ -z "$OUTPUT_FILE" ]; then
    OUTPUT_FILE="${INPUT_FILE%.json}.proof"
fi

# Determine proof service URL
PROOF_SERVICE="${PROOF_SERVICE_URL:-http://localhost:8080}"

# Check if proof service is available
echo "Checking proof service at: $PROOF_SERVICE"
if ! curl -s -f "${PROOF_SERVICE}/health" > /dev/null 2>&1; then
    echo "Warning: Proof service not available at $PROOF_SERVICE"
    echo "Using fallback mock generation..."
    
    # Fallback to mock proof generation
    sleep 2
    cat > "$OUTPUT_FILE" <<EOPROOF
{
  "proof": {
    "pi_a": ["0x$(openssl rand -hex 32)", "0x$(openssl rand -hex 32)"],
    "pi_b": [["0x$(openssl rand -hex 32)", "0x$(openssl rand -hex 32)"], 
             ["0x$(openssl rand -hex 32)", "0x$(openssl rand -hex 32)"]],
    "pi_c": ["0x$(openssl rand -hex 32)", "0x$(openssl rand -hex 32)"],
    "protocol": "${PROOF_TYPE}"
  },
  "public_signals": ["0x0000000000000000000000000000000000000001"],
  "verification_key": "0x$(openssl rand -hex 64)",
  "metadata": {
    "circuit": "$(basename $INPUT_FILE .json)",
    "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
    "prover": "midnight-prover-mock",
    "mode": "fallback"
  }
}
EOPROOF
    echo "✓ Mock proof generated (service unavailable)"
    echo "Output written to: $OUTPUT_FILE"
    exit 0
fi

# Read circuit data from input file
CIRCUIT_NAME=$(basename "$INPUT_FILE" .json)
if [ -f "$INPUT_FILE" ]; then
    CIRCUIT_DATA=$(cat "$INPUT_FILE")
else
    CIRCUIT_DATA="{}"
fi

# Prepare request payload
REQUEST_PAYLOAD=$(cat <<EOPAYLOAD
{
  "contract": "${CIRCUIT_NAME}",
  "protocol": "${PROOF_TYPE}",
  "inputs": ${CIRCUIT_DATA}
}
EOPAYLOAD
)

echo "Generating proof for circuit: $CIRCUIT_NAME"
echo "Protocol: $PROOF_TYPE"
echo "Contacting proof service..."

# Call the proof service
RESPONSE=$(curl -s -X POST \
    -H "Content-Type: application/json" \
    -d "$REQUEST_PAYLOAD" \
    "${PROOF_SERVICE}/proof/generate" 2>/dev/null)

# Check if request was successful
if [ $? -ne 0 ] || [ -z "$RESPONSE" ]; then
    echo "Error: Failed to generate proof"
    exit 1
fi

# Check for error in response
if echo "$RESPONSE" | grep -q '"success":false'; then
    ERROR_MSG=$(echo "$RESPONSE" | jq -r '.error // "Unknown error"' 2>/dev/null || echo "Unknown error")
    echo "Error from proof service: $ERROR_MSG"
    exit 1
fi

# Save the proof
echo "$RESPONSE" | jq '.' > "$OUTPUT_FILE" 2>/dev/null || echo "$RESPONSE" > "$OUTPUT_FILE"

echo "✓ Proof generated successfully!"
echo "Output written to: $OUTPUT_FILE"

# Verify proof if requested
if [ "$VERIFY_AFTER" = true ]; then
    echo ""
    echo "Verifying proof..."
    
    # Extract proof data for verification
    PROOF_DATA=$(jq '.proof' "$OUTPUT_FILE" 2>/dev/null)
    PUBLIC_SIGNALS=$(jq '.publicSignals' "$OUTPUT_FILE" 2>/dev/null)
    VERIFICATION_KEY=$(jq '.verificationKey' "$OUTPUT_FILE" 2>/dev/null)
    
    VERIFY_PAYLOAD=$(cat <<EOVERIFY
{
  "proof": ${PROOF_DATA:-{}},
  "publicSignals": ${PUBLIC_SIGNALS:-[]},
  "verificationKey": ${VERIFICATION_KEY:-null}
}
EOVERIFY
)
    
    VERIFY_RESPONSE=$(curl -s -X POST \
        -H "Content-Type: application/json" \
        -d "$VERIFY_PAYLOAD" \
        "${PROOF_SERVICE}/proof/verify" 2>/dev/null)
    
    if echo "$VERIFY_RESPONSE" | grep -q '"valid":true'; then
        echo "✓ Proof verified successfully!"
    else
        echo "⚠ Proof verification failed or could not be completed"
    fi
fi
EOF
RUN chmod +x /opt/midnight/bin/prove

# Create verify command
RUN cat > /opt/midnight/bin/verify <<'EOF'
#!/bin/bash
# Midnight proof verifier

if [ $# -eq 0 ]; then
    echo "Usage: verify <proof-file>"
    echo "Verifies a zero-knowledge proof using the configured proof service"
    exit 1
fi

PROOF_FILE="$1"

if [ ! -f "$PROOF_FILE" ]; then
    echo "Error: Proof file not found: $PROOF_FILE"
    exit 1
fi

# Determine proof service URL
PROOF_SERVICE="${PROOF_SERVICE_URL:-http://localhost:8080}"

echo "Verifying proof from: $PROOF_FILE"
echo "Using service: $PROOF_SERVICE"

# Check if proof service is available
if ! curl -s -f "${PROOF_SERVICE}/health" > /dev/null 2>&1; then
    echo "Error: Proof service not available at $PROOF_SERVICE"
    exit 1
fi

# Read and send proof for verification
RESPONSE=$(curl -s -X POST \
    -H "Content-Type: application/json" \
    -d @"$PROOF_FILE" \
    "${PROOF_SERVICE}/proof/verify" 2>/dev/null)

if [ $? -ne 0 ]; then
    echo "Error: Failed to contact proof service"
    exit 1
fi

# Check verification result
if echo "$RESPONSE" | grep -q '"valid":true'; then
    echo "✅ Proof verification successful!"
    
    # Extract and display additional information
    TIMESTAMP=$(echo "$RESPONSE" | jq -r '.timestamp // empty' 2>/dev/null)
    if [ -n "$TIMESTAMP" ]; then
        echo "  Timestamp: $TIMESTAMP"
    fi
    
    # Show proof details
    CIRCUIT=$(cat "$PROOF_FILE" | jq -r '.circuit // empty' 2>/dev/null)
    PROTOCOL=$(cat "$PROOF_FILE" | jq -r '.proof.protocol // empty' 2>/dev/null)
    
    if [ -n "$CIRCUIT" ]; then
        echo "  Circuit: $CIRCUIT"
    fi
    if [ -n "$PROTOCOL" ]; then
        echo "  Protocol: $PROTOCOL"
    fi
    
    echo "✓ Proof is VALID"
else
    echo "❌ Proof verification failed!"
    
    # Try to extract error message
    ERROR_MSG=$(echo "$RESPONSE" | jq -r '.error // .message // empty' 2>/dev/null)
    if [ -n "$ERROR_MSG" ]; then
        echo "  Error: $ERROR_MSG"
    else
        # Check if response is empty or service unavailable
        if [ -z "$RESPONSE" ]; then
            echo "  Error: No response from proof service"
            echo "  Check that the proof service is running at: $PROOF_SERVICE"
        else
            echo "  Response: $RESPONSE"
        fi
    fi
    echo "✗ Proof is INVALID"
    exit 1
fi
    exit 1
fi
EOF
RUN chmod +x /opt/midnight/bin/verify

# Create directories for proof server and OpenCode
RUN mkdir -p /opt/midnight/lib /opt/midnight/config && \
    mkdir -p /etc/skel/.config/opencode && \
    mkdir -p /root/.config/opencode

# Create an enhanced mock proof server that mimics the real API
# This will be replaced with the real server once we confirm the image structure
RUN cat > /opt/midnight/bin/proof-server <<'EOF'
#!/usr/bin/env node
const http = require('http');
const crypto = require('crypto');

const PORT = process.env.PROOF_SERVICE_PORT || 8080;
const HOST = process.env.PROOF_SERVICE_HOST || '0.0.0.0';
const LOG_LEVEL = process.env.PROOF_SERVICE_LOG_LEVEL || 'info';

function log(level, message) {
    if (LOG_LEVEL === 'debug' || 
        (LOG_LEVEL === 'info' && level !== 'debug') ||
        (LOG_LEVEL === 'warn' && (level === 'warn' || level === 'error')) ||
        (LOG_LEVEL === 'error' && level === 'error')) {
        console.log(`[${new Date().toISOString()}] [${level.toUpperCase()}] ${message}`);
    }
}

const server = http.createServer((req, res) => {
    res.setHeader('Content-Type', 'application/json');
    res.setHeader('Access-Control-Allow-Origin', '*');
    
    if (req.method === 'OPTIONS') {
        res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
        res.setHeader('Access-Control-Allow-Headers', 'Content-Type');
        res.writeHead(200);
        res.end();
        return;
    }
    
    const url = req.url;
    log('debug', `${req.method} ${url}`);
    
    if (url === '/health') {
        res.writeHead(200);
        res.end(JSON.stringify({
            status: 'healthy',
            version: '4.0.0-mock',
            service: 'midnight-proof-server',
            mode: 'mock'
        }));
    } else if (url === '/metrics') {
        res.writeHead(200);
        res.end(JSON.stringify({
            proofs_generated: Math.floor(Math.random() * 100),
            proofs_verified: Math.floor(Math.random() * 50),
            average_generation_time_ms: 500 + Math.random() * 1000,
            cache_hits: Math.floor(Math.random() * 30)
        }));
    } else if (url === '/circuits') {
        res.writeHead(200);
        res.end(JSON.stringify({
            circuits: [
                'proveBalance',
                'proveTransfer', 
                'batchVerifyBalances',
                'proveSolvency'
            ]
        }));
    } else if (url === '/proof/generate' && req.method === 'POST') {
        let body = '';
        req.on('data', chunk => body += chunk);
        req.on('end', () => {
            try {
                const input = JSON.parse(body);
                log('info', `Generating proof for circuit: ${input.circuit || 'default'}`);
                
                // Simulate proof generation delay
                setTimeout(() => {
                    const proof = {
                        proof: {
                            pi_a: [crypto.randomBytes(32).toString('hex')],
                            pi_b: [[crypto.randomBytes(32).toString('hex')]],
                            pi_c: [crypto.randomBytes(32).toString('hex')],
                            protocol: input.protocol || 'groth16'
                        },
                        publicSignals: input.publicSignals || [],
                        circuit: input.circuit || 'default',
                        timestamp: new Date().toISOString(),
                        success: true
                    };
                    
                    res.writeHead(200);
                    res.end(JSON.stringify(proof));
                    log('info', 'Proof generated successfully');
                }, 500);
            } catch (e) {
                log('error', `Failed to generate proof: ${e.message}`);
                res.writeHead(400);
                res.end(JSON.stringify({
                    success: false,
                    error: e.message
                }));
            }
        });
    } else if (url === '/proof/verify' && req.method === 'POST') {
        let body = '';
        req.on('data', chunk => body += chunk);
        req.on('end', () => {
            try {
                const input = JSON.parse(body);
                log('info', 'Verifying proof...');
                
                // Mock verification - check for valid proof structure
                let valid = false;
                
                // Check if we have a proof object with the expected structure
                if (input.proof) {
                    // Check for groth16 proof structure
                    if (input.proof.pi_a && input.proof.pi_b && input.proof.pi_c) {
                        valid = true;
                        log('debug', 'Valid groth16 proof structure detected');
                    }
                    // Check for nested proof structure
                    else if (input.proof.proof) {
                        valid = true;
                        log('debug', 'Valid nested proof structure detected');
                    }
                }
                // Also accept if the whole input is the proof structure  
                else if (input.pi_a && input.pi_b && input.pi_c) {
                    valid = true;
                    log('debug', 'Valid direct proof structure detected');
                }
                
                res.writeHead(200);
                res.end(JSON.stringify({
                    valid: valid,
                    timestamp: new Date().toISOString()
                }));
                log('info', `Proof verification result: ${valid}`);
            } catch (e) {
                log('error', `Failed to verify proof: ${e.message}`);
                res.writeHead(400);
                res.end(JSON.stringify({
                    valid: false,
                    error: e.message
                }));
            }
        });
    } else {
        res.writeHead(404);
        res.end(JSON.stringify({
            error: 'Not found',
            path: url
        }));
    }
});

server.listen(PORT, HOST, () => {
    log('info', `Midnight Proof Server (Mock) running on http://${HOST}:${PORT}`);
    log('info', 'Mode: Mock Service - Real proof server integration pending');
    log('info', `Configuration: threads=${process.env.PROOF_SERVICE_THREADS || 4}, cache_size=${process.env.PROOF_SERVICE_CACHE_SIZE || 1000}`);
});

// Graceful shutdown
process.on('SIGTERM', () => {
    log('info', 'Shutting down proof server...');
    server.close(() => {
        log('info', 'Proof server stopped');
        process.exit(0);
    });
});
EOF
RUN chmod +x /opt/midnight/bin/proof-server

# Add Midnight tools to PATH
ENV PATH="/opt/midnight/bin:${PATH}"
ENV LD_LIBRARY_PATH="/opt/midnight/lib:${LD_LIBRARY_PATH}"

# Proof service configuration
# PROOF_SERVICE_MODE: local (default) or external
# PROOF_SERVICE_URL: URL for external proof service (ignored in local mode)
ENV PROOF_SERVICE_MODE="local"
ENV PROOF_SERVICE_URL=""
ENV PROOF_SERVICE_PORT="8080"
ENV PROOF_SERVICE_HOST="0.0.0.0"
ENV PROOF_SERVICE_LOG_LEVEL="info"
ENV PROOF_SERVICE_THREADS="4"
ENV PROOF_SERVICE_CACHE_SIZE="1000"

# Google Cloud / Vertex AI configuration
ENV GCP_PROJECT_ID=""
ENV GOOGLE_APPLICATION_CREDENTIALS=""

# Create workspace directories
RUN mkdir -p /workspace/templates && \
    mkdir -p /workspace/projects && \
    mkdir -p /workspace/.midnight

# Copy scripts
COPY scripts/startup.sh /etc/workstation-startup.d/200_midnight_setup.sh
COPY scripts/web-terminal.js /opt/opencode-terminal/web-terminal.js
COPY scripts/package.json /opt/opencode-terminal/package.json
COPY scripts/.terminal_profile /etc/profile.d/midnight.sh
COPY scripts/configure-opencode.sh /usr/local/bin/configure-opencode
COPY scripts/opencode-config-template.json /etc/skel/.config/opencode/opencode.json.template
COPY scripts/opencode-config-template.json /etc/skel/.config/opencode/opencode.json
COPY scripts/opencode-config-template.json /root/.config/opencode/opencode.json
COPY scripts/update-midnight-extension.sh /usr/local/bin/update-midnight-extension
COPY scripts/update-templates.sh /opt/scripts/update-templates.sh
COPY scripts/Token.compact.template /opt/scripts/Token.compact.template
COPY scripts/Makefile.template /opt/scripts/Makefile.template
COPY scripts/Makefile.fixed /opt/scripts/Makefile.fixed
COPY scripts/token.test.js.template /opt/scripts/token.test.js.template
COPY scripts/package.json.template /opt/scripts/package.json.template
COPY scripts/test-circuit.sh /opt/scripts/test-circuit.sh

# Install web terminal dependencies
WORKDIR /opt/opencode-terminal
RUN npm install

# Make scripts executable
RUN chmod +x /etc/workstation-startup.d/200_midnight_setup.sh && \
    chmod +x /opt/opencode-terminal/web-terminal.js && \
    chmod +x /etc/profile.d/midnight.sh && \
    chmod +x /usr/local/bin/configure-opencode && \
    chmod +x /usr/local/bin/update-midnight-extension && \
    chmod +x /opt/scripts/update-templates.sh && \
    chmod +x /opt/scripts/test-circuit.sh

# Copy templates
COPY templates/ /workspace/templates/

# Create welcome script (will be dynamic at runtime)
RUN cat > /workspace/welcome.sh <<'EOF'
#!/bin/bash
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║                                                              ║"
echo "║        🌙  Midnight Development Platform - MVP  🌙          ║"
echo "║                                                              ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""
echo "👋 Welcome! This is your cloud-native development environment for"
echo "   building privacy-preserving DApps on Midnight Network."
echo ""
echo "🛠️  Available Commands:"
echo "  • midnight new <project>         - Create new DApp project"
echo "  • midnight compile               - Compile Compact contracts"
echo "  • midnight test                  - Run contract tests"
echo "  • midnight prove                 - Generate ZK proofs"
echo "  • midnight verify <proof>        - Verify a proof file"
echo "  • midnight deploy                - Deploy to testnet"
echo "  • opencode-ai                    - AI-powered code assistant (CLI)"
echo "  • compactc                       - Midnight Compact compiler"
echo "  • prove                          - ZK proof generator"
echo "  • verify                         - ZK proof verifier"
echo "  • npm/node                       - JavaScript development"
echo ""
echo "🌐 Web Services (Access in Browser):"
echo "  • http://localhost:${TERMINAL_PORT:-7681}/services - Service Dashboard (all services)"
echo "  • http://localhost:${TERMINAL_PORT:-7681}          - Web Terminal"
echo "  • http://localhost:${TERMINAL_PORT:-7681}/opencode - OpenCode AI Assistant"
echo "  • http://localhost:${CODE_PORT:-8443}              - VS Code IDE"

# Show proof service URL (configured or default)
PROOF_URL="${PROOF_SERVICE_URL:-http://localhost:8080}"
if [ "$PROOF_URL" != "http://localhost:8080" ]; then
    echo "  • ${PROOF_URL}/health - Proof Service API (external)"
else
    echo "  • ${PROOF_URL}/health - Proof Service API (local)"
fi

echo ""
echo "📚 Resources:"
echo "  • Documentation: /workspace/docs"
echo "  • Templates: /workspace/templates"
echo "  • Examples: /workspace/templates/basic-token"
echo ""

# Show configuration info if available
if [ -n "$MIDNIGHT_ENV" ]; then
    echo "⚙️  Configuration:"
    echo "  • Environment: $MIDNIGHT_ENV"
    [ -n "$MIDNIGHT_NETWORK" ] && echo "  • Network: $MIDNIGHT_NETWORK"
    [ -n "$GCP_PROJECT_ID" ] && echo "  • GCP Project: $GCP_PROJECT_ID"
    [ -n "$PROOF_SERVICE_URL" ] && [ "$PROOF_SERVICE_URL" != "http://localhost:8080" ] && echo "  • Proof Service: $PROOF_SERVICE_URL"
    echo ""
fi

echo "💡 Try: cd /workspace/templates/basic-token && make compile"
echo "   Or: opencode (for AI assistance)"
echo ""
EOF
RUN chmod +x /workspace/welcome.sh

# Create opencode config directories (let opencode create its own config)
RUN mkdir -p /etc/skel/.config/opencode && \
    mkdir -p /root/.config/opencode && \
    chmod 755 /root/.config/opencode

# Create a default user directory structure (will be used if user is created)
RUN mkdir -p /home && chmod 755 /home

# Set default working directory
WORKDIR /workspace

# Expose ports
# 3000 - DApp development server
# 8080 - Proof service
# 7681 - OpenCode Web Terminal
EXPOSE 3000 8080 7681

# Configure VS Code settings
RUN mkdir -p /etc/skel/.config/Code/User && \
    mkdir -p /root/.config/Code/User && \
    cat > /tmp/vscode-settings.json <<'EOF'
{
  "terminal.integrated.defaultProfile.linux": "bash",
  "terminal.integrated.profiles.linux": {
    "bash": {
      "path": "/bin/bash",
      "args": ["-l"]
    }
  },
  "workbench.colorTheme": "Default Dark+",
  "editor.formatOnSave": true,
  "editor.minimap.enabled": false,
  "editor.fontSize": 14,
  "terminal.integrated.fontSize": 14,
  "files.autoSave": "afterDelay",
  "files.autoSaveDelay": 1000,
  "extensions.autoUpdate": true,
  "files.associations": {
    "*.compact": "compact",
    "*.zk": "compact"
  },
  "[compact]": {
    "editor.tabSize": 4,
    "editor.insertSpaces": true,
    "editor.formatOnSave": true
  },
  "midnight.compact": {
    "formatOnSave": true,
    "lintOnSave": true,
    "compiler": {
      "path": "/opt/midnight/bin/compactc",
      "outputDir": "build"
    }
  }
}
EOF

# Copy VS Code settings to multiple locations
RUN cp /tmp/vscode-settings.json /etc/skel/.config/Code/User/settings.json && \
    cp /tmp/vscode-settings.json /root/.config/Code/User/settings.json && \
    rm /tmp/vscode-settings.json

# Install VS Code extensions
RUN code-server --install-extension dbaeumer.vscode-eslint && \
    code-server --install-extension esbenp.prettier-vscode && \
    code-server --install-extension eamodio.gitlens && \
    code-server --install-extension ms-vscode.makefile-tools || true

# Install Midnight Compact language extension for VS Code
RUN echo "Installing Midnight Compact VSCode extension..." && \
    mkdir -p /tmp/midnight-extension && \
    curl -L -o /tmp/midnight-extension/compact.vsix \
        "https://raw.githubusercontent.com/midnight-ntwrk/releases/gh-pages/artifacts/vscode-extension/compact-0.2.13/compact-0.2.13.vsix" && \
    code-server --install-extension /tmp/midnight-extension/compact.vsix && \
    rm -rf /tmp/midnight-extension && \
    echo "Midnight Compact extension installed successfully"

# Final cleanup
RUN apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Create entrypoint script
RUN cat > /entrypoint.sh <<'EOF'
#!/bin/bash
# Entrypoint for Midnight Development Platform

# Set VS Code to use a non-privileged port
export PORT=8443
export CS_DISABLE_FILE_DOWNLOADS=1
export CODE_SERVER_PORT=8443

# Run startup scripts (continue on error for compatibility)
if [ -d /etc/workstation-startup.d ]; then
    for script in /etc/workstation-startup.d/*.sh; do
        if [ -x "$script" ]; then
            # Skip problematic startup scripts
            script_name="$(basename $script)"
            if [[ "$script_name" == "110_start-code-oss.sh" ]] || [[ "$script_name" == "000_configure-docker.sh" ]]; then
                echo "Skipping $script_name (not needed for Podman)"
                continue
            fi
            echo "Running startup script: $script_name"
            "$script" 2>&1 | grep -v "Error: listen EACCES" || true
        fi
    done
fi

# Display welcome message
if [ -f /workspace/welcome.sh ]; then
    /workspace/welcome.sh
fi

# Start a bash shell or execute command
if [ $# -eq 0 ]; then
    # Keep container running when started in detached mode
    if [ -t 0 ]; then
        exec /bin/bash
    else
        # Run a sleep loop to keep container alive
        echo "Container ready. Services are running."
        exec tail -f /dev/null
    fi
else
    exec "$@"
fi
EOF

# Make entrypoint executable
RUN chmod +x /entrypoint.sh

# Set entrypoint
ENTRYPOINT ["/entrypoint.sh"]