#!/bin/bash
#
# Configure /etc/bash.bashrc to ensure GCP_PROJECT_ID is set for all shells
# This runs very early (before 050) to ensure it's ready for all processes
#

echo "Configuring bash environment for GCP project detection..."

# Create bash.bashrc.d directory for modular configuration
mkdir -p /etc/bash.bashrc.d

# Ensure /etc/bash.bashrc sources our configuration
if [ -f /etc/bash.bashrc ]; then
    # Check if we already have our source line
    if ! grep -q "bash.bashrc.d" /etc/bash.bashrc 2>/dev/null; then
        # Add at the beginning of the file (after initial comments)
        cat >> /etc/bash.bashrc << 'EOF'

# Source additional configurations from bash.bashrc.d
if [ -d /etc/bash.bashrc.d ]; then
    for script in /etc/bash.bashrc.d/*.sh; do
        [ -r "$script" ] && . "$script"
    done
fi

# Auto-detect GCP Project ID for Cloud Workstations
if [ -z "$GCP_PROJECT_ID" ]; then
    # Try metadata service
    _gcp_project=$(curl -s -f -H "Metadata-Flavor: Google" \
        "http://metadata.google.internal/computeMetadata/v1/project/project-id" 2>/dev/null)
    if [ -n "$_gcp_project" ]; then
        export GCP_PROJECT_ID="$_gcp_project"
        export GOOGLE_CLOUD_PROJECT="$_gcp_project"
    fi
    unset _gcp_project
fi
EOF
        echo "✓ Updated /etc/bash.bashrc with GCP auto-detection"
    fi
else
    echo "Warning: /etc/bash.bashrc not found, creating it"
    cat > /etc/bash.bashrc << 'EOF'
# System-wide .bashrc file for interactive bash(1) shells.

# Source additional configurations from bash.bashrc.d
if [ -d /etc/bash.bashrc.d ]; then
    for script in /etc/bash.bashrc.d/*.sh; do
        [ -r "$script" ] && . "$script"
    done
fi

# Auto-detect GCP Project ID for Cloud Workstations
if [ -z "$GCP_PROJECT_ID" ]; then
    # Try metadata service
    _gcp_project=$(curl -s -f -H "Metadata-Flavor: Google" \
        "http://metadata.google.internal/computeMetadata/v1/project/project-id" 2>/dev/null)
    if [ -n "$_gcp_project" ]; then
        export GCP_PROJECT_ID="$_gcp_project"
        export GOOGLE_CLOUD_PROJECT="$_gcp_project"
    fi
    unset _gcp_project
fi
EOF
fi

echo "✓ Bash environment configured for GCP project detection"