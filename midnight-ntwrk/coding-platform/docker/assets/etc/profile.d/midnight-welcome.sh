#!/bin/bash
#
# Midnight Development Workstation - Welcome Message and Environment Setup
# This file is sourced by all login shells
#

# Auto-detect and export GCP project ID for Cloud Workstations
if [ -z "$GCP_PROJECT_ID" ] && [ -n "$CLOUD_WORKSTATIONS_CONFIG_DIRECTORY" ]; then
    export GCP_PROJECT_ID=$(curl -s -H "Metadata-Flavor: Google" \
        "http://metadata.google.internal/computeMetadata/v1/project/project-id" 2>/dev/null)
fi

# Only show in interactive terminals
if [[ $- == *i* ]]; then
    # Check if we're in a terminal and haven't shown the message yet
    if [ -t 1 ] && [ -z "$MIDNIGHT_WELCOME_SHOWN" ]; then
        export MIDNIGHT_WELCOME_SHOWN=1
        
        echo "=========================================="
        echo "Midnight Development Workstation"
        echo "=========================================="
        echo ""
        echo "Services available:"
        echo "  • Code OSS IDE (current window)"
        echo "  • Proof Server: http://localhost:8081"
        echo ""
        echo "Tools available:"
        echo "  • opencode - AI coding assistant (Vertex AI)"
        echo "  • midnight - Midnight CLI tool"
        echo "  • compactc - Compact compiler"
        echo "  • prove - Proof generation"
        echo "  • verify - Proof verification"
        echo ""
        
        # Show GCP project if in Cloud Workstation
        if [ -n "$CLOUD_WORKSTATIONS_CONFIG_DIRECTORY" ]; then
            GCP_PROJECT=$(curl -s -H "Metadata-Flavor: Google" \
                "http://metadata.google.internal/computeMetadata/v1/project/project-id" 2>/dev/null)
            if [ -n "$GCP_PROJECT" ]; then
                echo "GCP Project: $GCP_PROJECT"
                export GCP_PROJECT_ID="$GCP_PROJECT"
            fi
        fi
        
        echo ""
        echo "Quick start:"
        echo "  • Run 'opencode' for AI assistance"
        echo "  • Run 'midnight new my-project' to create a project"
        echo "  • Check ~/workspace for templates and samples"
        echo ""
    fi
fi

# Ensure OpenCode directories exist
if [ -n "$HOME" ]; then
    mkdir -p "$HOME/.local/share/opencode/log" 2>/dev/null
    mkdir -p "$HOME/.config/opencode" 2>/dev/null
fi

# Export useful environment variables
export MIDNIGHT_HOME="/opt/midnight"
export PATH="/opt/midnight/bin:$PATH"