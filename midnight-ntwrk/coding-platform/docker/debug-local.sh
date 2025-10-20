#!/bin/bash
# Debug script to troubleshoot Code OSS startup

echo "Debug Mode - Midnight Workstation"
echo "=================================="
echo ""
echo "System Info:"
echo "  User: $(whoami) (UID: $(id -u))"
echo "  Working dir: $(pwd)"
echo "  HOME: $HOME"
echo ""

# Check for Code OSS binary
echo "Checking for Code OSS binary..."
if [ -f /opt/code-oss/bin/codeoss-cloudworkstations ]; then
    echo "✓ Found: /opt/code-oss/bin/codeoss-cloudworkstations"
    ls -la /opt/code-oss/bin/codeoss-cloudworkstations
else
    echo "✗ Not found: /opt/code-oss/bin/codeoss-cloudworkstations"
    echo ""
    echo "Looking for Code OSS files..."
    find /opt -type f -name "*code*" 2>/dev/null | grep -E "(bin|exe)" | head -10
fi

# Check Node.js
echo ""
echo "Checking Node.js..."
which node && node --version || echo "✗ Node.js not found"

# Set up environment
export HOME=/tmp/user-home
mkdir -p $HOME/.codeoss-cloudworkstations/data
mkdir -p $HOME/.codeoss-cloudworkstations/extensions

# Try to start Code OSS in foreground with verbose output
echo ""
echo "Starting Code OSS in debug mode..."
echo "=================================="
exec /opt/code-oss/bin/codeoss-cloudworkstations \
    --port 8080 \
    --host 0.0.0.0 \
    --without-connection-token \
    --disable-telemetry \
    --user-data-dir $HOME/.codeoss-cloudworkstations/data \
    --extensions-dir $HOME/.codeoss-cloudworkstations/extensions \
    --verbose