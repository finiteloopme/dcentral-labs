#!/bin/bash
#
# Configure Code OSS for local development.
#

set -euo pipefail

STARTUP_SCRIPT="/etc/workstation-startup.d/110_start-code-oss.sh"

echo "Configuring Code OSS..."

# Modify the startup script to detect environment at runtime:
# - Google Cloud Workstations: use port 80 (proxied by GCP infrastructure)
# - Local/other environments: use port 8080 (non-privileged)
if [[ -f "$STARTUP_SCRIPT" ]]; then
    # Use awk to replace the hardcoded port line with runtime detection logic
    awk '{
        if ($0 ~ /^export EDITOR_PORT=80$/) {
            print "# Detect environment and set appropriate port"
            print "if curl -s -m 1 metadata.google.internal > /dev/null 2>&1; then"
            print "    export EDITOR_PORT=80"
            print "else"
            print "    export EDITOR_PORT=${EDITOR_PORT:-8080}"
            print "fi"
        } else {
            print $0
        }
    }' "$STARTUP_SCRIPT" > "${STARTUP_SCRIPT}.tmp" && \
    mv "${STARTUP_SCRIPT}.tmp" "$STARTUP_SCRIPT" && \
    chmod +x "$STARTUP_SCRIPT"
    
    echo "Code OSS configured for runtime environment detection (GCP: 80, local: 8080)"
else
    echo "Warning: Code OSS startup script not found at $STARTUP_SCRIPT"
fi

echo "Code OSS configuration complete."
