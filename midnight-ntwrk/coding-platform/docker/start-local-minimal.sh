#!/bin/bash
# Minimal startup script for local development
# Focuses on essential services without Code OSS complexity

echo "Starting Midnight Workstation (Minimal Mode)"
echo "============================================"
echo ""
echo "Running as: $(whoami) (UID: $(id -u), GID: $(id -g))"
echo ""

# Use /tmp for writable directories
export HOME=/tmp/user-home
mkdir -p $HOME

# Start proof server only
echo "Starting Midnight Proof Server on port 8081..."
cd /opt/midnight/proof-server
PORT=8081 npm start &
PROOF_PID=$!

# Simple HTTP server for documentation
echo "Starting documentation server on port 8080..."
mkdir -p $HOME/www
cat > $HOME/www/index.html << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>Midnight Development Workstation</title>
    <style>
        body { 
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; 
            margin: 0; 
            padding: 40px;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            min-height: 100vh;
        }
        .container {
            max-width: 800px;
            margin: 0 auto;
        }
        h1 { 
            font-size: 3em;
            margin-bottom: 0.5em;
            text-shadow: 2px 2px 4px rgba(0,0,0,0.3);
        }
        .card {
            background: rgba(255,255,255,0.1);
            backdrop-filter: blur(10px);
            border-radius: 15px;
            padding: 30px;
            margin: 20px 0;
            box-shadow: 0 8px 32px 0 rgba(31, 38, 135, 0.37);
            border: 1px solid rgba(255,255,255,0.18);
        }
        .status { 
            display: flex;
            align-items: center;
            margin: 15px 0;
            font-size: 1.2em;
        }
        .status-icon {
            margin-right: 10px;
            font-size: 1.5em;
        }
        .ok { color: #4ade80; }
        .warn { color: #fbbf24; }
        .service-list {
            list-style: none;
            padding: 0;
        }
        .service-list li {
            margin: 15px 0;
            padding: 15px;
            background: rgba(255,255,255,0.1);
            border-radius: 8px;
            display: flex;
            justify-content: space-between;
            align-items: center;
        }
        .service-link {
            color: #60a5fa;
            text-decoration: none;
            font-weight: bold;
        }
        .service-link:hover {
            color: #93c5fd;
            text-decoration: underline;
        }
        .command {
            background: rgba(0,0,0,0.3);
            padding: 15px;
            border-radius: 8px;
            font-family: 'Courier New', monospace;
            margin: 10px 0;
            border-left: 4px solid #60a5fa;
        }
        .tools-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 15px;
            margin: 20px 0;
        }
        .tool {
            background: rgba(255,255,255,0.1);
            padding: 15px;
            border-radius: 8px;
            text-align: center;
        }
        .tool-name {
            font-weight: bold;
            color: #60a5fa;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>🌙 Midnight Development Workstation</h1>
        
        <div class="card">
            <h2>📊 Status</h2>
            <div class="status ok">
                <span class="status-icon">✅</span>
                <span>Container is running</span>
            </div>
            <div class="status ok">
                <span class="status-icon">✅</span>
                <span>Proof Server is active</span>
            </div>
            <div class="status warn">
                <span class="status-icon">ℹ️</span>
                <span>Running in minimal mode (no IDE)</span>
            </div>
        </div>

        <div class="card">
            <h2>🔗 Services</h2>
            <ul class="service-list">
                <li>
                    <span>Proof Server API</span>
                    <a href="http://localhost:8081/health" class="service-link">http://localhost:8081/health</a>
                </li>
                <li>
                    <span>API Documentation</span>
                    <a href="http://localhost:8081/api/info" class="service-link">http://localhost:8081/api/info</a>
                </li>
            </ul>
        </div>

        <div class="card">
            <h2>🛠️ Available Tools</h2>
            <div class="tools-grid">
                <div class="tool">
                    <div class="tool-name">midnight</div>
                    <div>CLI tool</div>
                </div>
                <div class="tool">
                    <div class="tool-name">compactc</div>
                    <div>Compiler</div>
                </div>
                <div class="tool">
                    <div class="tool-name">prove</div>
                    <div>Proof generator</div>
                </div>
                <div class="tool">
                    <div class="tool-name">verify</div>
                    <div>Proof verifier</div>
                </div>
                <div class="tool">
                    <div class="tool-name">opencode</div>
                    <div>AI assistant</div>
                </div>
            </div>
        </div>

        <div class="card">
            <h2>💻 Access Container</h2>
            <p>To access the container's shell and use the CLI tools:</p>
            <div class="command">podman exec -it midnight-local /bin/bash</div>
            
            <p>Then you can use:</p>
            <div class="command">opencode  # AI coding assistant (requires ANTHROPIC_API_KEY)</div>
            <div class="command">midnight new my-project  # Create new project</div>
            <div class="command">compactc contract.compact  # Compile contracts</div>
        </div>

        <div class="card">
            <h2>🚀 For Full IDE Experience</h2>
            <p>This minimal mode doesn't include Code OSS IDE. For full IDE functionality:</p>
            <ol>
                <li>Use VS Code locally with Remote Containers extension</li>
                <li>Or deploy to Google Cloud Workstations for the full web IDE</li>
            </ol>
        </div>
    </div>
</body>
</html>
EOF

cd $HOME/www
python3 -m http.server 8080 > /tmp/web-server.log 2>&1 &
WEB_PID=$!

echo ""
echo "Services starting..."
sleep 3

# Check services
echo ""
echo "Services available:"
echo "  • Documentation: http://localhost:8080"
echo "  • Proof Server API: http://localhost:8081/health"
echo ""
echo "CLI Tools (exec into container to use):"
echo "  • opencode - AI coding assistant"
echo "  • midnight - Midnight CLI tool"
echo "  • compactc - Compact language compiler"
echo ""
echo "To access the container:"
echo "  podman exec -it midnight-local /bin/bash"
echo ""
echo "Press Ctrl+C to stop"

# Keep running
tail -f /tmp/web-server.log /tmp/proof-server.log 2>/dev/null