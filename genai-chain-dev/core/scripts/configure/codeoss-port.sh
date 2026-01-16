#!/bin/bash
#
# Configure Code OSS to use port 8080 when running locally.
#
# The Google Cloud Workstations base image hardcodes EDITOR_PORT=80, which
# requires root privileges. This script patches the startup script to detect
# the environment at runtime:
#   - GCP Cloud Workstations: use port 80 (proxied by GCP infrastructure)
#   - Local/other environments: use port 8080 (non-privileged)
#

set -euo pipefail

STARTUP_SCRIPT="/etc/workstation-startup.d/110_start-code-oss.sh"

echo "Configuring Code OSS port..."

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
    
    echo "  Code OSS configured (GCP: port 80, local: port 8080)"
else
    echo "  Warning: Code OSS startup script not found at $STARTUP_SCRIPT"
fi
