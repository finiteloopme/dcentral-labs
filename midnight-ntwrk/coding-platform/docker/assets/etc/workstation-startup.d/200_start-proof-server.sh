#!/bin/bash
#
# Start Midnight proof server (only if not using external service)
#

# Check if we're using an external proof service
if [ "$PROOF_SERVICE_MODE" = "external" ] && [ -n "$PROOF_SERVICE_URL" ]; then
  echo "Using external proof service: $PROOF_SERVICE_URL"
  echo "Skipping local proof server startup"
  
  # Optionally test connection to external service
  if command -v curl >/dev/null 2>&1; then
    echo "Testing connection to external proof service..."
    if curl -s -f -o /dev/null -w "  HTTP %{http_code}\n" "$PROOF_SERVICE_URL/health" 2>/dev/null; then
      echo "✓ External proof service is reachable"
    else
      echo "⚠ Warning: Could not reach external proof service health endpoint"
      echo "  The service may still work if it doesn't have a /health endpoint"
    fi
  fi
  exit 0
fi

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

echo "Starting local Midnight proof server on port 8081..."

# Ensure the proof server directory exists and has dependencies
if [ ! -d "/opt/midnight/proof-server" ]; then
  echo "⚠ Proof server directory not found, skipping..."
  exit 0
fi

cd /opt/midnight/proof-server

# Check if dependencies are installed
if [ ! -d "node_modules" ]; then
  echo "Installing proof server dependencies..."
  npm install --production --silent
fi

# Start the server
PORT=8081 nohup node src/server.js > /tmp/proof-server.log 2>&1 &
PROOF_PID=$!

# Wait a moment and check if it started
sleep 2
if kill -0 $PROOF_PID 2>/dev/null; then
  echo "✓ Local proof server started (PID: $PROOF_PID, logs: /tmp/proof-server.log)"
  echo $PROOF_PID > /tmp/proof-server.pid
else
  echo "⚠ Failed to start proof server, check /tmp/proof-server.log"
fi