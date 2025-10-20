#!/bin/bash
#
# Initialize Midnight workspace
#

# In Cloud Workstations, this runs as the workstation user
# In local dev, this might run as root and switch to user
if [[ "${EUID:-$(id -u)}" -eq 0 ]]; then
  # If running as root (local dev), switch to user if available
  if id user >/dev/null 2>&1; then
    exec runuser user "${BASH_SOURCE[0]}"
  else
    # No user account yet, skip for now
    exit 0
  fi
fi

echo "Initializing Midnight workspace..."

# Create workspace directories
mkdir -p ~/workspace/projects ~/workspace/templates

# Copy templates if not present
if [ ! -d ~/workspace/templates/basic-token ]; then
  cp -r /opt/templates/* ~/workspace/templates/ 2>/dev/null || true
fi

# Create sample project if workspace is empty
if [ ! -d ~/workspace/projects/sample-token ]; then
  cp -r /opt/templates/basic-token ~/workspace/projects/sample-token 2>/dev/null || true
  echo "Created sample project at ~/workspace/projects/sample-token"
fi

echo "✓ Workspace initialization complete"