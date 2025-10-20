#!/bin/bash
# Start Midnight Proof Server

PROOF_SERVER_DIR="/opt/midnight/proof-server"
LOG_FILE="/var/log/proof-server.log"
PORT="${PROOF_SERVICE_PORT:-8080}"

echo "Starting Midnight Proof Server on port $PORT..."

# Check if proof server directory exists
if [ ! -d "$PROOF_SERVER_DIR" ]; then
    echo "Error: Proof server not found at $PROOF_SERVER_DIR"
    exit 1
fi

# Check if Node.js is available
if ! command -v node &> /dev/null; then
    echo "Error: Node.js is not installed"
    exit 1
fi

# Navigate to proof server directory
cd "$PROOF_SERVER_DIR"

# Check if package.json exists
if [ ! -f "package.json" ]; then
    echo "Error: package.json not found in $PROOF_SERVER_DIR"
    exit 1
fi

# Start the proof server in the background
export PORT=$PORT
nohup npm start > "$LOG_FILE" 2>&1 &
PROOF_PID=$!

# Wait a moment for the server to start
sleep 2

# Check if the server is running
if kill -0 $PROOF_PID 2>/dev/null; then
    echo "✓ Proof server started successfully (PID: $PROOF_PID)"
    echo "  Logs: $LOG_FILE"
    echo "  URL: http://localhost:$PORT"
else
    echo "✗ Failed to start proof server"
    echo "  Check logs at: $LOG_FILE"
    exit 1
fi