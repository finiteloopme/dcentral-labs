#!/bin/bash
# Wrapper script for Code OSS terminals to ensure they run as non-root

# Debug: Log that wrapper is being called
echo "[Terminal Wrapper] Starting..." >&2

# Switch to non-root user with proper environment
if [ "$(id -u)" = "0" ]; then
    echo "[Terminal Wrapper] Running as root, switching to ubuntu user..." >&2
    # Disable problematic scripts
    export SKIP_GCLOUD_INIT=1
    
    # Get the user's home directory - handle if ubuntu doesn't exist yet
    if id ubuntu &>/dev/null 2>&1; then
        USER_HOME=$(getent passwd ubuntu | cut -d: -f6)
    else
        # Create ubuntu user if it doesn't exist
        useradd -m -s /bin/bash -u 1000 -g 0 ubuntu
        echo "ubuntu ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
        USER_HOME="/home/ubuntu"
    fi
    
    # Ensure directories exist for OpenCode
    mkdir -p $USER_HOME/.local/share/opencode/log 2>/dev/null
    mkdir -p $USER_HOME/.config/opencode 2>/dev/null
    chown -R ubuntu:ubuntu $USER_HOME/.local 2>/dev/null
    chown -R ubuntu:ubuntu $USER_HOME/.config 2>/dev/null
    
    # Switch to ubuntu user with proper environment
    exec su - ubuntu -c "
        export PS1='\\u@localhost:\\w\\$ '
        export PATH=/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:/opt/midnight/bin:\$PATH
        export TERM=xterm-256color
        export HOME=$USER_HOME
        export USER_HOME=$USER_HOME
        
        # Create directories if they don't exist
        mkdir -p \$HOME/.local/share/opencode/log 2>/dev/null
        mkdir -p \$HOME/.config/opencode 2>/dev/null
        
        echo 'Terminal running as: '\$(whoami)' (UID: '\$(id -u)')'
        echo 'Services: Code OSS at http://127.0.0.1:8080 | Proof Server at http://127.0.0.1:8081'
        echo ''
        echo 'To use OpenCode TUI (with Vertex AI):'
        echo '  1. Check gcloud auth: gcloud auth list'
        echo '  2. Run: opencode'
        echo ''
        exec /bin/bash -i
    "
else
    # Already non-root
    exec /bin/bash
fi