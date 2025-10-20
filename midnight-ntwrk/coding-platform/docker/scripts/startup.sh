#!/bin/bash
# Midnight Development Platform - Startup Script

# Silent initialization - welcome message comes later

# Setup automatic authentication (silently)
if [ -f /opt/midnight/bin/auto-auth ]; then
    source /opt/midnight/bin/auto-auth 2>/dev/null || true
fi

# Configure OpenCode silently if we have a project
if [ -n "$GCP_PROJECT_ID" ] && [ -x /usr/local/bin/configure-opencode ]; then
    /usr/local/bin/configure-opencode 2>/dev/null || true
fi

# Install Midnight Compact VSCode extension silently if not already installed
if command -v code-server &> /dev/null || command -v code &> /dev/null; then
    # Determine which VS Code command to use
    if command -v code-server &> /dev/null; then
        VSCODE_CMD="code-server"
    else
        VSCODE_CMD="code"
    fi
    
    # Check if extension is already installed
    if ! $VSCODE_CMD --list-extensions 2>/dev/null | grep -q "midnight.compact"; then
        if [ -f /opt/midnight/extensions/compact-0.2.13.vsix ]; then
            $VSCODE_CMD --install-extension /opt/midnight/extensions/compact-0.2.13.vsix &>/dev/null 2>&1 || true
        fi
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

# Ensure midnight CLI is available
# The actual midnight.sh script should be copied and renamed during Docker build
if [ ! -f /usr/local/bin/midnight ] && [ -f /opt/midnight/bin/midnight ]; then
    ln -sf /opt/midnight/bin/midnight /usr/local/bin/midnight
fi

# Copy templates to workspace if they don't exist
if [ ! -d /workspace/templates ]; then
    mkdir -p /workspace/templates
    
    # Try copying from various possible locations
    if [ -d /opt/templates ]; then
        cp -r /opt/templates/* /workspace/templates/ 2>/dev/null || true
    elif [ -d /docker/templates ]; then
        cp -r /docker/templates/* /workspace/templates/ 2>/dev/null || true
    fi
fi

# Ensure templates are in the right place
if [ -d /docker/templates/basic-token ] && [ ! -d /workspace/templates/basic-token ]; then
    mkdir -p /workspace/templates
    cp -r /docker/templates/basic-token /workspace/templates/ 2>/dev/null || true
fi

# Set up Git configuration
git config --global user.name "Midnight Developer" 2>/dev/null || true
git config --global user.email "developer@midnight.network" 2>/dev/null || true
git config --global init.defaultBranch main 2>/dev/null || true

# Configure proof service based on mode
PROOF_SERVICE_MODE="${PROOF_SERVICE_MODE:-local}"
PROOF_SERVICE_PORT="${PROOF_SERVICE_PORT:-8080}"
PROOF_SERVICE_URL="${PROOF_SERVICE_URL:-}"

case "$PROOF_SERVICE_MODE" in
    local)
        # Start local proof server silently
        if [ -x "/opt/midnight/bin/proof-server" ] && command -v node &> /dev/null; then
            # Use our enhanced proof server
            /opt/midnight/bin/proof-server &>/dev/null 2>&1 &
        else
            # Fallback to simple mock server
            while true; do
                echo -e "HTTP/1.1 200 OK\r\nContent-Type: application/json\r\n\r\n{\"status\":\"ok\",\"version\":\"4.0.0\"}" | nc -l -p "$PROOF_SERVICE_PORT" -q 1
            done &>/dev/null 2>&1 &
        fi
        
        export PROOF_SERVICE_URL="http://localhost:$PROOF_SERVICE_PORT"
        ;;
    
    external)
        if [ -z "$PROOF_SERVICE_URL" ]; then
            echo "Warning: External proof service mode selected but PROOF_SERVICE_URL not set"
            echo "Please set PROOF_SERVICE_URL environment variable"
        else
            echo "Using external proof service: $PROOF_SERVICE_URL"
            
            # Test connectivity
            if command -v curl &> /dev/null; then
                if curl -s --connect-timeout 2 "$PROOF_SERVICE_URL/health" &> /dev/null; then
                    echo "✓ Connected to proof service"
                else
                    echo "⚠ Could not reach proof service at $PROOF_SERVICE_URL"
                fi
            fi
        fi
        ;;
    
    none)
        echo "Proof service disabled"
        ;;
    
    *)
        echo "Unknown proof service mode: $PROOF_SERVICE_MODE"
        echo "Valid modes: local, external, none"
        ;;
esac

# Create workspace directories if they don't exist
mkdir -p /workspace/projects /workspace/templates /workspace/examples

# Show welcome message
echo ""
echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║     🌙 Midnight Development Environment Ready!                ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo ""
echo "📡 Web Services:"
echo "  • VS Code:       http://localhost:80"
echo "  • Proof Service: http://localhost:8080"
echo "  • Web Terminal:  http://localhost:7681"
echo "  • Dev Server:    http://localhost:3000 (when running)"
echo ""
echo "🛠️  Midnight Commands:"
echo "  • midnight new <name>  - Create a new DApp project"
echo "  • midnight compile     - Compile Compact contracts"
echo "  • midnight test        - Run contract tests"
echo "  • midnight prove       - Generate zero-knowledge proofs"
echo "  • midnight verify      - Verify proof files"
echo "  • midnight serve       - Start development server"
echo ""
echo "🔧 Development Tools:"
echo "  • compactc             - Midnight Compact compiler"
echo "  • prove                - Proof generation tool"
echo "  • verify               - Proof verification tool"
echo "  • opencode             - AI coding assistant"
echo "  • code                 - Open VS Code editor"
echo ""
echo "📂 Quick Navigation:"
echo "  • workspace            - Go to /workspace"
echo "  • projects             - Go to /workspace/projects"
echo "  • cd /workspace/templates - View contract templates"
echo ""
echo "💡 Getting Started:"
echo "  1. Create a project:  midnight new my-token"
echo "  2. Enter project:     cd /workspace/projects/my-token"
echo "  3. Compile contracts: midnight compile"
echo "  4. Run tests:         midnight test"
echo ""
echo "Type 'midnight help' for more information"
echo "═══════════════════════════════════════════════════════════════"
echo ""