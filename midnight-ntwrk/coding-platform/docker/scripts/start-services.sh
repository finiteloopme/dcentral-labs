#!/bin/bash
# Start all Midnight services

echo "Starting Midnight services..."

# Start web terminal on port 7681
if command -v ttyd >/dev/null 2>&1; then
    echo "Starting web terminal on port 7681..."
    ttyd -p 7681 -W /bin/bash &
else
    echo "Note: Web terminal not available"
fi

# Start VS Code server on port 8443 (only if explicitly requested)
if [ "$START_CODE_SERVER" = "true" ] && command -v code-server >/dev/null 2>&1; then
    echo "Starting VS Code server on port 8443..."
    code-server --bind-addr 0.0.0.0:8443 --auth none --disable-telemetry &
fi

# Start proof service on port 8080 (mock service)
if [ "$START_PROOF_SERVICE" = "true" ]; then
    echo "Starting mock proof service on port 8080..."
    # Simple Python HTTP server as mock proof service
    cat > /tmp/proof-service.py <<'PYEOF'
from http.server import HTTPServer, BaseHTTPRequestHandler
import json

class ProofHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        self.send_response(200)
        self.send_header('Content-type', 'application/json')
        self.end_headers()
        response = {"status": "ready", "service": "midnight-proof-service", "version": "1.0.0"}
        self.wfile.write(json.dumps(response).encode())
    
    def do_POST(self):
        content_length = int(self.headers['Content-Length'])
        post_data = self.rfile.read(content_length)
        self.send_response(200)
        self.send_header('Content-type', 'application/json')
        self.end_headers()
        response = {"status": "success", "proof": "mock_proof_" + str(hash(post_data))[:8]}
        self.wfile.write(json.dumps(response).encode())
    
    def log_message(self, format, *args):
        pass  # Suppress logs

if __name__ == '__main__':
    server = HTTPServer(('0.0.0.0', 8080), ProofHandler)
    print("Mock proof service running on port 8080")
    server.serve_forever()
PYEOF
    python3 /tmp/proof-service.py &
fi

# Simple web server on port 3000
if [ "$START_WEB_SERVER" = "true" ]; then
    echo "Starting web server on port 3000..."
    cd /workspace && python3 -m http.server 3000 --bind 0.0.0.0 >/dev/null 2>&1 &
fi

echo ""
echo "Services started:"
echo "  • Web Terminal: http://localhost:7681"
[ "$START_CODE_SERVER" = "true" ] && echo "  • VS Code IDE: http://localhost:8443"
[ "$START_PROOF_SERVICE" = "true" ] && echo "  • Proof Service: http://localhost:8080"
[ "$START_WEB_SERVER" = "true" ] && echo "  • Web Server: http://localhost:3000"
echo ""
echo "Tools available:"
echo "  • opencode - AI coding assistant"
echo "  • compactc - Compile Midnight contracts"
echo "  • prove - Generate proofs"
echo "  • verify - Verify proofs"
echo ""

# Keep services running
tail -f /dev/null