#!/bin/bash
# Entrypoint for local testing - starts services and provides non-root shell

echo "Starting Midnight Workstation (Local Mode)"
echo "=========================================="
echo ""

# Create non-root user first if needed
if ! id 1000 &>/dev/null 2>&1; then
    useradd -m -s /bin/bash -u 1000 -g 0 ubuntu
    echo "ubuntu ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
fi

# Start services as root (they need port 80)
echo "Starting services..."

    # Start Code OSS on port 80 with user configuration
    if [ -f /opt/code-oss/bin/codeoss-cloudworkstations ]; then
        echo "Starting Code OSS on port 80..."
        
        # Copy terminal wrapper if provided
        if [ -f /terminal-wrapper.sh ]; then
            cp /terminal-wrapper.sh /usr/local/bin/terminal-wrapper
            chmod +x /usr/local/bin/terminal-wrapper
            echo "✓ Terminal wrapper installed at /usr/local/bin/terminal-wrapper"
        else
            echo "⚠️  Warning: terminal-wrapper.sh not found, terminals will run as root"
        fi
        
        # Clear any cached Code OSS settings
        rm -rf /root/.codeoss-cloudworkstations/data/Machine/settings.json 2>/dev/null
        
        # Configure Code OSS to use non-root user for terminals in local dev
        mkdir -p /root/.codeoss-cloudworkstations/data/Machine
        cat > /root/.codeoss-cloudworkstations/data/Machine/settings.json << 'EOSETTINGS'
{
    "terminal.integrated.defaultProfile.linux": "non-root-terminal",
    "terminal.integrated.profiles.linux": {
        "non-root-terminal": {
            "path": "/usr/local/bin/terminal-wrapper",
            "args": [],
            "overrideName": true,
            "icon": "terminal"
        },
        "root-terminal": {
            "path": "/bin/bash",
            "overrideName": true,
            "icon": "warning"
        }
    },
    "files.associations": {
        "*.compact": "compact"
    },
    "workbench.colorTheme": "Default Dark Modern",
    "editor.fontSize": 14,
    "terminal.integrated.fontSize": 14
}
EOSETTINGS
        
        /opt/code-oss/bin/codeoss-cloudworkstations \
            --port 80 \
            --host 0.0.0.0 \
            --without-connection-token \
            --disable-telemetry \
            --user-data-dir /root/.codeoss-cloudworkstations/data &
        sleep 2
    fi

# Start proof server on port 8081
echo "Starting Proof Server on port 8081..."
cd /opt/midnight/proof-server
PORT=8081 npm start &
sleep 2

echo ""
echo "Services running:"
echo "  Code OSS: http://127.0.0.1:8080 (mapped from port 80)"
echo "  Proof Server: http://127.0.0.1:8081"
echo "  Note: Use 127.0.0.1, not localhost"
echo ""

# Create non-root user for terminal work
if [ "$(id -u)" = "0" ]; then
    # Check if there's already a user with UID 1000
    if id 1000 &>/dev/null 2>&1; then
        WORK_USER=$(id -nu 1000)
        echo "Using existing user: $WORK_USER (UID 1000)"
    else
        # Create a new user
        WORK_USER="developer"
        useradd -m -s /bin/bash -u 1000 -g 0 $WORK_USER
        echo "$WORK_USER ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
        echo "Created user: $WORK_USER (UID 1000)"
    fi
    
    # Ensure home directory is usable
    USER_HOME="/home/$WORK_USER"
    if [ ! -d "$USER_HOME" ]; then
        USER_HOME="/tmp/workspace"
        mkdir -p $USER_HOME
        chown 1000:0 $USER_HOME
    fi
    
    # Copy gcloud credentials if mounted at temp location
    if [ -d "/tmp/gcloud-config" ]; then
        echo "Setting up gcloud configuration..."
        # Create the gcloud config directory
        mkdir -p $USER_HOME/.config/gcloud
        
        # Copy essential files and directories
        if [ -f "/tmp/gcloud-config/application_default_credentials.json" ]; then
            cp /tmp/gcloud-config/application_default_credentials.json $USER_HOME/.config/gcloud/
        fi
        
        if [ -f "/tmp/gcloud-config/active_config" ]; then
            cp /tmp/gcloud-config/active_config $USER_HOME/.config/gcloud/
        fi
        
        if [ -d "/tmp/gcloud-config/configurations" ]; then
            cp -r /tmp/gcloud-config/configurations $USER_HOME/.config/gcloud/
        fi
        
        # Set proper ownership for the entire gcloud directory
        chown -R 1000:0 $USER_HOME/.config/gcloud
        
        echo "✓ Google Cloud credentials configured"
    fi
    
    echo ""
    echo "Switching to non-root user for terminal..."
    echo "Working as: $WORK_USER"
    echo "Home: $USER_HOME"
    echo ""
    echo "To use OpenCode TUI:"
    echo "  opencode"
    echo ""
    echo "OpenCode is configured to use Vertex AI with your gcloud credentials"
    echo ""
    
    # Disable problematic profile scripts for local development
    for script in /etc/profile.d/*gcloud* /etc/profile.d/*gce*; do
        if [ -f "$script" ]; then
            mv "$script" "$script.disabled" 2>/dev/null || true
        fi
    done
    
    # Create a clean bashrc for the user (with proper variable expansion)
    cat > $USER_HOME/.bashrc << EOF
# Simple prompt
PS1='\u@midnight:\w\$ '

# Aliases
alias ll='ls -la'
alias l='ls -l'

# Environment
export PATH=/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:/opt/midnight/bin:\$PATH
export HOME=$USER_HOME
export USER_HOME=$USER_HOME
export TERM=xterm-256color
export GCP_PROJECT_ID="${GCP_PROJECT_ID:-}"

# Create necessary directories for OpenCode
mkdir -p \$HOME/.local/share/opencode/log 2>/dev/null
mkdir -p \$HOME/.config/opencode 2>/dev/null

# Create OpenCode configuration if it doesn't exist (local development)
if [ ! -f \$HOME/.config/opencode/config.json ]; then
    echo "Creating OpenCode configuration for local development..."
    # Copy from template if available
    if [ -f /opt/midnight/bin/opencode-config-template.json ]; then
        cp /opt/midnight/bin/opencode-config-template.json \$HOME/.config/opencode/config.json
    elif [ -f /docker/scripts/opencode-config-template.json ]; then
        cp /docker/scripts/opencode-config-template.json \$HOME/.config/opencode/config.json
    else
        # Create basic config with both Vertex AI and Anthropic options
        cat > \$HOME/.config/opencode/config.json << 'OPENCODE_CONFIG'
{
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
        "project": "\${GCP_PROJECT_ID}",
        "location": "us-central1"
      }
    },
    "anthropic": {
      "models": {
        "claude-3-opus-20240229": {},
        "claude-3-5-sonnet-20241022": {},
        "claude-3-5-haiku-20241022": {}
      },
      "options": {
        "apiKey": "\${ANTHROPIC_API_KEY}"
      }
    }
  }
}
OPENCODE_CONFIG
    fi
    chown ubuntu:ubuntu \$HOME/.config/opencode/config.json 2>/dev/null || true
fi

# Function to launch OpenCode with Vertex AI
opencode() {
    # Ensure log directory exists
    mkdir -p \$HOME/.local/share/opencode/log 2>/dev/null
    
    # Check for application default credentials (what Vertex AI actually uses)
    if [ ! -f "\$HOME/.config/gcloud/application_default_credentials.json" ]; then
        echo "Warning: No Google Cloud application default credentials found"
        echo "OpenCode needs these for Vertex AI access"
        echo ""
        echo "On your host machine, run:"
        echo "  gcloud auth application-default login"
        echo ""
        echo "Then restart this container"
        return 1
    fi
    
    # Check if GCP project is set
    if [ -z "\$GCP_PROJECT_ID" ]; then
        echo "Warning: GCP_PROJECT_ID not set"
        echo "You can set it when starting the container:"
        echo "  GCP_PROJECT_ID=your-project-id make run-local"
        echo ""
        echo "Or it should be auto-detected from your gcloud config"
    else
        echo "Using GCP project: \$GCP_PROJECT_ID"
    fi
    
    # Launch OpenCode with Vertex AI configuration
    HOME=\$HOME USER_HOME=\$HOME TERM=xterm-256color \\
        GCP_PROJECT_ID="\$GCP_PROJECT_ID" \\
        OPENCODE_MODEL="vertex-ai/claude-3-5-sonnet@20241022" \\
        /usr/bin/opencode "\$@"
}

echo "Welcome to Midnight Development Workstation (Local Mode)"
echo "========================================================="
echo ""
echo "Services available:"
echo "  • Code OSS: http://127.0.0.1:8080  (Note: use 127.0.0.1, not localhost)"
echo "  • Proof Server: http://127.0.0.1:8081"
echo ""
echo "Tools available:"
echo "  • opencode - AI coding assistant (uses Vertex AI with gcloud auth)"
echo "  • midnight - Midnight CLI"
echo "  • compactc - Compact compiler"
echo ""

# Show GCP project if set
if [ -n "\$GCP_PROJECT_ID" ]; then
    echo "GCP Project: \$GCP_PROJECT_ID"
else
    echo "GCP Project: Not set (will need to specify for Vertex AI)"
fi

echo ""
echo "To use OpenCode TUI with Vertex AI:"
echo "  Run: opencode"
echo ""
EOF
    chown $WORK_USER:0 $USER_HOME/.bashrc
    
    # Switch to non-root user with proper terminal
    cd $USER_HOME
    exec su - $WORK_USER
else
    # Already non-root
    echo "Running as: $(whoami)"
    /bin/bash
fi