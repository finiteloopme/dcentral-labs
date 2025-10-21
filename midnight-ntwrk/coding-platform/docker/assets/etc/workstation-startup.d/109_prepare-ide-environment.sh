#!/bin/bash
#
# Prepare environment for IDE (runs right before 110_start-code-oss.sh)
# This ensures environment variables are available in Code OSS terminals
#

echo "Preparing IDE environment variables..."

# Try to get GCP project ID if not already set
if [ -z "$GCP_PROJECT_ID" ]; then
    # Try metadata service
    PROJECT_ID=$(curl -s -f -H "Metadata-Flavor: Google" \
        "http://metadata.google.internal/computeMetadata/v1/project/project-id" 2>/dev/null || true)
    
    if [ -n "$PROJECT_ID" ]; then
        export GCP_PROJECT_ID="$PROJECT_ID"
        export GOOGLE_CLOUD_PROJECT="$PROJECT_ID"
        echo "Set GCP_PROJECT_ID=$PROJECT_ID for IDE"
    fi
fi

# Create a wrapper script for Code OSS that ensures environment is set
if [ -f /opt/code-oss/bin/codeoss-cloudworkstations ]; then
    # Back up original if not already done
    if [ ! -f /opt/code-oss/bin/codeoss-cloudworkstations.original ]; then
        mv /opt/code-oss/bin/codeoss-cloudworkstations /opt/code-oss/bin/codeoss-cloudworkstations.original
    fi
    
    # Create wrapper that sets environment
    cat > /opt/code-oss/bin/codeoss-cloudworkstations << 'EOF'
#!/bin/bash
# Wrapper to ensure GCP environment is set for Code OSS

# Source environment if available
[ -f /etc/environment ] && export $(grep -v '^#' /etc/environment | xargs -0)

# Try to get GCP project if not set
if [ -z "$GCP_PROJECT_ID" ]; then
    GCP_PROJECT_ID=$(curl -s -f -H "Metadata-Flavor: Google" \
        "http://metadata.google.internal/computeMetadata/v1/project/project-id" 2>/dev/null || true)
    [ -n "$GCP_PROJECT_ID" ] && export GCP_PROJECT_ID
    [ -n "$GCP_PROJECT_ID" ] && export GOOGLE_CLOUD_PROJECT="$GCP_PROJECT_ID"
fi

# Launch original Code OSS with environment
exec /opt/code-oss/bin/codeoss-cloudworkstations.original "$@"
EOF
    
    chmod +x /opt/code-oss/bin/codeoss-cloudworkstations
    echo "✓ Created Code OSS wrapper to ensure GCP environment"
fi

# Also ensure it's in the user's shell initialization
# This catches cases where the terminal doesn't source system files
for user_home in /home/user /home/*; do
    if [ -d "$user_home" ] && [ "$user_home" != "/home/*" ]; then
        # Add to .profile if it exists (sourced by sh/dash)
        if [ -f "$user_home/.profile" ]; then
            if ! grep -q "GCP_PROJECT_ID" "$user_home/.profile" 2>/dev/null; then
                cat >> "$user_home/.profile" << 'EOF'

# Auto-detect GCP Project ID
if [ -z "$GCP_PROJECT_ID" ]; then
    GCP_PROJECT_ID=$(curl -s -f -H "Metadata-Flavor: Google" \
        "http://metadata.google.internal/computeMetadata/v1/project/project-id" 2>/dev/null || true)
    [ -n "$GCP_PROJECT_ID" ] && export GCP_PROJECT_ID
    [ -n "$GCP_PROJECT_ID" ] && export GOOGLE_CLOUD_PROJECT="$GCP_PROJECT_ID"
fi
EOF
                echo "Added GCP auto-detection to $user_home/.profile"
            fi
        fi
        
        # Add to .bashrc as a last resort (but avoid if possible)
        # Only if it exists and doesn't already have it
        if [ -f "$user_home/.bashrc" ] && [ ! -f "$user_home/.profile" ]; then
            if ! grep -q "GCP_PROJECT_ID" "$user_home/.bashrc" 2>/dev/null; then
                # Add at the very top after the interactive check
                sed -i '/^# If not running interactively/a\
\
# Auto-detect GCP Project ID\
if [ -z "$GCP_PROJECT_ID" ]; then\
    GCP_PROJECT_ID=$(curl -s -f -H "Metadata-Flavor: Google" \\\
        "http://metadata.google.internal/computeMetadata/v1/project/project-id" 2>/dev/null || true)\
    [ -n "$GCP_PROJECT_ID" ] && export GCP_PROJECT_ID\
    [ -n "$GCP_PROJECT_ID" ] && export GOOGLE_CLOUD_PROJECT="$GCP_PROJECT_ID"\
fi\
' "$user_home/.bashrc" 2>/dev/null || true
            fi
        fi
    fi
done

echo "✓ IDE environment preparation complete"