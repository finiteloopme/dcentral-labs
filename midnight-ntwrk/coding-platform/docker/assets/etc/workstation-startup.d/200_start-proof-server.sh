#!/bin/bash
#
# Start Midnight proof server
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

echo "Starting Midnight proof server on port 8081..."
cd /opt/midnight/proof-server
PORT=8081 nohup npm start > /tmp/proof-server.log 2>&1 &
echo "Proof server started (logs: /tmp/proof-server.log)"