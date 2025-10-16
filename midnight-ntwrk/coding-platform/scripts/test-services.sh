#!/bin/bash
# Test if services are accessible

source "$(dirname "$0")/common.sh"

echo "Testing service endpoints..."
echo ""

# Test proof service
echo -n "Proof Service (http://localhost:8080/health): "
if curl -s http://localhost:8080/health | grep -q "healthy"; then
    echo "✅ OK"
else
    echo "❌ Not accessible"
fi

# Test web terminal
echo -n "OpenCode Terminal (http://localhost:7681): "
if curl -s -o /dev/null -w "%{http_code}" http://localhost:7681 | grep -q "200"; then
    echo "✅ OK"
else
    echo "❌ Not accessible"
fi

# Test if opencode is installed in container
echo -n "OpenCode AI command: "
if podman exec midnight-local which opencode-ai 2>/dev/null; then
    echo "✅ Found"
elif podman exec midnight-local which opencode 2>/dev/null; then
    echo "✅ Found (as 'opencode')"
else
    echo "❌ Not found"
fi

echo ""
echo "You can now access:"
echo "  • OpenCode Terminal: http://localhost:7681"
echo "  • Proof Service API: http://localhost:8080/health"