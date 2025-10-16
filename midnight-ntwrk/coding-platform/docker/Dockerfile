# Start with base Cloud Workstations image
FROM us-central1-docker.pkg.dev/cloud-workstations-images/predefined/code-oss:latest

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

# Install OpenCode AI assistant
RUN npm install -g opencode-ai

# Install code-server for VS Code in browser
RUN curl -fsSL https://code-server.dev/install.sh | sh

# Install packages for web terminal server
RUN npm install -g \
    express \
    express-ws \
    node-pty \
    @xterm/xterm

# Create Midnight tools directory and add mock compiler
RUN mkdir -p /opt/midnight/bin && \
    mkdir -p /opt/midnight/lib

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

INPUT_FILE="${!#}"
OUTPUT_FILE="${INPUT_FILE%.compact}.json"

if [ ! -f "$INPUT_FILE" ]; then
    echo "Error: Input file '$INPUT_FILE' not found"
    exit 1
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
# Mock Midnight proof generator for MVP

echo "Midnight Proof Generator v0.1.0-mvp"
echo "===================================="

if [ $# -eq 0 ]; then
    echo "Usage: prove [options] <input-file>"
    echo "Options:"
    echo "  -o <output>  Specify output file"
    echo "  -t <type>    Proof type (zk-snark, zk-stark)"
    echo "  --verify     Verify proof after generation"
    exit 1
fi

INPUT_FILE="${!#}"
OUTPUT_FILE="${INPUT_FILE%.json}.proof"

echo "Generating zero-knowledge proof..."
echo "Circuit: $(basename $INPUT_FILE .json)"
sleep 2
echo "Computing witness..."
sleep 1
echo "Generating proof..."
sleep 1.5

# Generate mock proof
cat > "$OUTPUT_FILE" <<EOPROOF
{
  "proof": {
    "pi_a": ["0x1234567890abcdef", "0xfedcba0987654321"],
    "pi_b": [["0xaabbccdd", "0xeeff0011"], ["0x22334455", "0x66778899"]],
    "pi_c": ["0x11223344", "0x55667788"],
    "protocol": "groth16"
  },
  "public_signals": ["0x0000000000000000000000000000000000000001"],
  "verification_key": "0xabcdef123456789",
  "metadata": {
    "circuit": "$(basename $INPUT_FILE .json)",
    "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
    "prover": "midnight-prover-0.1.0"
  }
}
EOPROOF

echo "✓ Proof generated successfully!"
echo "Output written to: $OUTPUT_FILE"
EOF
RUN chmod +x /opt/midnight/bin/prove

# Add Midnight tools to PATH
ENV PATH="/opt/midnight/bin:${PATH}"

# Create workspace directories
RUN mkdir -p /workspace/templates && \
    mkdir -p /workspace/projects && \
    mkdir -p /workspace/.midnight

# Copy scripts
COPY scripts/startup.sh /etc/workstation-startup.d/200_midnight_setup.sh
COPY scripts/web-terminal.js /opt/opencode-terminal/web-terminal.js
COPY scripts/package.json /opt/opencode-terminal/package.json
COPY scripts/.terminal_profile /etc/profile.d/midnight.sh

# Install web terminal dependencies
WORKDIR /opt/opencode-terminal
RUN npm install

# Make scripts executable
RUN chmod +x /etc/workstation-startup.d/200_midnight_setup.sh && \
    chmod +x /opt/opencode-terminal/web-terminal.js && \
    chmod +x /etc/profile.d/midnight.sh

# Copy templates
COPY templates/ /workspace/templates/

# Create welcome script
RUN cat > /workspace/welcome.sh <<'EOF'
#!/bin/bash
clear
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║         Welcome to Midnight Development Platform            ║"
echo "║                        MVP v0.1.0                           ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""
echo "🚀 Quick Start Commands:"
echo "  • midnight new <project-name>    - Create new DApp project"
echo "  • midnight compile               - Compile Compact contracts"
echo "  • midnight test                  - Run contract tests"
echo "  • midnight prove                 - Generate ZK proofs"
echo "  • midnight deploy                - Deploy to testnet"
echo ""
echo "🛠️ Development Tools:"
echo "  • opencode-ai                    - AI-powered code assistant (CLI)"
echo "  • code .                         - Open VS Code in current directory"
echo "  • npm/node                       - JavaScript development"
echo ""
echo "🌐 Web Services (Access in Browser):"
echo "  • http://localhost:7681/services - Service Dashboard (all services)"
echo "  • http://localhost:7681          - Web Terminal"
echo "  • http://localhost:7681/opencode - OpenCode AI Assistant"
echo "  • http://localhost:7681/vscode   - VS Code IDE"
echo "  • http://localhost:8080/health   - Proof Service API"
echo ""
echo "📚 Resources:"
echo "  • Documentation: /workspace/docs"
echo "  • Templates: /workspace/templates"
echo "  • Examples: /workspace/templates/basic-token"
echo ""
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
  "extensions.autoUpdate": true
}
EOF

# Copy VS Code settings to multiple locations
RUN cp /tmp/vscode-settings.json /etc/skel/.config/Code/User/settings.json && \
    cp /tmp/vscode-settings.json /root/.config/Code/User/settings.json && \
    rm /tmp/vscode-settings.json

# Install VS Code extensions (these will be suggestions)
RUN code-server --install-extension dbaeumer.vscode-eslint && \
    code-server --install-extension esbenp.prettier-vscode && \
    code-server --install-extension eamodio.gitlens && \
    code-server --install-extension ms-vscode.makefile-tools || true

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