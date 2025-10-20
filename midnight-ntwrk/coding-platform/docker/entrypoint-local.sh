#!/bin/bash
# Local development entrypoint wrapper
# This handles running locally when the container is built with USER 1000

echo "Starting Midnight Workstation (Local Development Mode)"

# Check if we're running as UID 1000 (the expected user)
if [ "$(id -u)" = "1000" ]; then
    echo "Running as UID 1000 (user)"
    
    # For local development, we can run Code OSS on port 8080 instead of 80
    # since port 80 requires special capabilities
    export PORT=8080
    
    # Start Code OSS directly on port 8080
    echo "Starting Code OSS on port 8080 (non-privileged)..."
    cd /home/user
    exec /opt/code-oss/bin/codeoss-cloudworkstations \
        --port 8080 \
        --host 0.0.0.0 \
        --without-connection-token \
        --disable-telemetry &
    
    # Start proof server
    echo "Starting proof server on port 8081..."
    cd /opt/midnight/proof-server
    npm start &
    
    # Keep container running
    echo "Services started. Container ready."
    tail -f /dev/null
else
    echo "Warning: Running as UID $(id -u), expected 1000"
    # Try to continue anyway
    exec "$@"
fi