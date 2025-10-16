#!/usr/bin/env node
/**
 * Web Terminal Server for OpenCode AI
 * Provides xterm.js interface for opencode-ai access
 */

const express = require('express');
const pty = require('node-pty');
const path = require('path');
const cors = require('cors');
const http = require('http');

const app = express();
const server = http.createServer(app);
const expressWs = require('express-ws')(app, server);

const PORT = process.env.TERMINAL_PORT || 7681;

// Enable CORS for all origins (configure as needed for production)
app.use(cors({
    origin: '*',
    methods: ['GET', 'POST', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization'],
    credentials: true
}));

// Serve static files
app.use(express.static(path.join(__dirname, 'public')));

// VS Code endpoint - redirect to code-server if running, otherwise show instructions
app.get('/vscode', (req, res) => {
    // Check if code-server is running on port 8443
    const http = require('http');
    http.get('http://localhost:8443', (response) => {
        // If code-server is running, redirect to it
        res.redirect('http://localhost:8443');
    }).on('error', () => {
        // If not running, show instructions
        res.send(`
<!DOCTYPE html>
<html>
<head>
    <title>VS Code - Midnight Development Platform</title>
    <style>
        body {
            margin: 0;
            padding: 0;
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            height: 100vh;
            display: flex;
            flex-direction: column;
            background: #1e1e1e;
        }
        .header {
            background: #2d2d2d;
            padding: 10px 20px;
            border-bottom: 1px solid #444;
            display: flex;
            align-items: center;
            justify-content: space-between;
            color: white;
        }
        .header h1 {
            margin: 0;
            font-size: 18px;
            font-weight: 500;
        }
        .container {
            flex: 1;
            display: flex;
            align-items: center;
            justify-content: center;
            padding: 20px;
        }
        .content {
            background: #252526;
            border-radius: 8px;
            padding: 40px;
            max-width: 600px;
            text-align: center;
            color: #cccccc;
        }
        .icon {
            font-size: 64px;
            margin-bottom: 20px;
        }
        .message {
            margin-bottom: 30px;
            line-height: 1.6;
        }
        .actions {
            display: flex;
            gap: 15px;
            justify-content: center;
            flex-wrap: wrap;
        }
        .btn {
            padding: 10px 20px;
            background: #0e639c;
            color: white;
            text-decoration: none;
            border-radius: 4px;
            transition: background 0.3s;
        }
        .btn:hover {
            background: #1177bb;
        }
        .btn-secondary {
            background: #3c3c3c;
        }
        .btn-secondary:hover {
            background: #505050;
        }
        .note {
            margin-top: 30px;
            padding: 15px;
            background: #1e1e1e;
            border-radius: 4px;
            font-size: 14px;
            border-left: 3px solid #007acc;
        }
        code {
            background: #1e1e1e;
            padding: 2px 6px;
            border-radius: 3px;
            font-family: 'Cascadia Code', 'Courier New', monospace;
        }
    </style>
</head>
<body>
    <div class="header">
        <h1>📝 VS Code - Midnight Development Platform</h1>
        <div>
            <a href="/services" style="color: #007acc; text-decoration: none;">← Back to Services</a>
        </div>
    </div>
    <div class="container">
        <div class="content">
            <div class="icon">📝</div>
            <h2>VS Code Server</h2>
            <div class="message">
                VS Code Server is available for advanced IDE features.<br>
                For the best experience, you can:
            </div>
            <div class="actions">
                <a href="/terminal" class="btn">Use Web Terminal</a>
                <a href="/opencode" class="btn btn-secondary">Use OpenCode AI</a>
            </div>
            <div class="note">
                <strong>💡 Tip:</strong> VS Code Server can be started manually in the terminal:<br>
                <code>code-server --bind-addr 0.0.0.0:8443</code><br><br>
                Then access it at <code>http://localhost:8443</code>
            </div>
            <div class="note" style="margin-top: 15px;">
                <strong>🚀 Quick Start:</strong><br>
                1. Open the <a href="/terminal" style="color: #007acc;">Web Terminal</a><br>
                2. Navigate to your project: <code>cd /workspace/templates/basic-token</code><br>
                3. Edit files: <code>nano contracts/Token.compact</code><br>
                4. Or use OpenCode AI for assistance: <a href="/opencode" style="color: #007acc;">Launch OpenCode</a>
            </div>
        </div>
    </div>
</body>
</html>
    `);
    });
});

// Landing page with service links
app.get('/services', (req, res) => {
    res.send(`
<!DOCTYPE html>
<html>
<head>
    <title>Midnight Development Platform - Services</title>
    <style>
        body {
            margin: 0;
            padding: 0;
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
        }
        .container {
            background: white;
            border-radius: 12px;
            padding: 40px;
            box-shadow: 0 20px 40px rgba(0,0,0,0.1);
            max-width: 800px;
            width: 90%;
        }
        h1 {
            color: #333;
            margin-bottom: 10px;
            text-align: center;
        }
        .subtitle {
            color: #666;
            text-align: center;
            margin-bottom: 40px;
        }
        .services {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
            gap: 20px;
        }
        .service-card {
            background: #f8f9fa;
            border: 1px solid #e0e0e0;
            border-radius: 8px;
            padding: 20px;
            text-decoration: none;
            color: inherit;
            transition: all 0.3s;
        }
        .service-card:hover {
            transform: translateY(-2px);
            box-shadow: 0 8px 16px rgba(0,0,0,0.1);
            background: #fff;
        }
        .service-icon {
            font-size: 32px;
            margin-bottom: 10px;
        }
        .service-title {
            font-size: 18px;
            font-weight: 600;
            color: #333;
            margin-bottom: 8px;
        }
        .service-desc {
            font-size: 14px;
            color: #666;
            line-height: 1.5;
        }
        .service-url {
            font-size: 12px;
            color: #999;
            margin-top: 10px;
            font-family: monospace;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>🌙 Midnight Development Platform</h1>
        <p class="subtitle">Choose a service to get started</p>
        
        <div class="services">
            <a href="/" class="service-card">
                <div class="service-icon">💻</div>
                <div class="service-title">Web Terminal</div>
                <div class="service-desc">Full bash terminal with Midnight tools and development environment</div>
                <div class="service-url">http://localhost:7681/</div>
            </a>
            
            <a href="/opencode" class="service-card">
                <div class="service-icon">🤖</div>
                <div class="service-title">OpenCode AI</div>
                <div class="service-desc">AI-powered coding assistant for smart contract development</div>
                <div class="service-url">http://localhost:7681/opencode</div>
            </a>
            
            <a href="/vscode" class="service-card">
                <div class="service-icon">📝</div>
                <div class="service-title">VS Code IDE</div>
                <div class="service-desc">Full-featured code editor with extensions and debugging</div>
                <div class="service-url">http://localhost:7681/vscode</div>
            </a>
            
            <a href="http://localhost:8080/health" target="_blank" class="service-card">
                <div class="service-icon">🔐</div>
                <div class="service-title">Proof Service</div>
                <div class="service-desc">Zero-knowledge proof generation and verification API</div>
                <div class="service-url">http://localhost:8080</div>
            </a>
            
            <a href="http://localhost:3000" target="_blank" class="service-card">
                <div class="service-icon">🚀</div>
                <div class="service-title">DApp Server</div>
                <div class="service-desc">Development server for your Midnight DApps</div>
                <div class="service-url">http://localhost:3000</div>
            </a>
        </div>
    </div>
</body>
</html>
    `);
});

// Serve different terminals based on path
app.get('/terminal', (req, res) => {
    res.redirect('/');
});

// Main terminal page
app.get('/', (req, res) => {
    res.send(`
<!DOCTYPE html>
<html>
<head>
    <title>OpenCode AI Terminal</title>
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/@xterm/xterm@5.5.0/css/xterm.css" />
    <style>
        body {
            margin: 0;
            padding: 0;
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            background: #1e1e1e;
            color: #fff;
            height: 100vh;
            display: flex;
            flex-direction: column;
        }
        .header {
            background: #2d2d2d;
            padding: 10px 20px;
            border-bottom: 1px solid #444;
            display: flex;
            align-items: center;
            justify-content: space-between;
        }
        .header h1 {
            margin: 0;
            font-size: 18px;
            font-weight: 500;
            color: #fff;
        }
        .header .status {
            display: flex;
            align-items: center;
            gap: 10px;
            font-size: 14px;
        }
        .status-indicator {
            width: 8px;
            height: 8px;
            border-radius: 50%;
            background: #4caf50;
            animation: pulse 2s infinite;
        }
        @keyframes pulse {
            0%, 100% { opacity: 1; }
            50% { opacity: 0.5; }
        }
        #terminal-container {
            flex: 1;
            padding: 10px;
            overflow: hidden;
        }
        #terminal {
            height: 100%;
            width: 100%;
        }
        .controls {
            background: #2d2d2d;
            padding: 10px 20px;
            border-top: 1px solid #444;
            display: flex;
            gap: 10px;
        }
        .controls button {
            padding: 6px 12px;
            background: #0066cc;
            color: white;
            border: none;
            border-radius: 4px;
            cursor: pointer;
            font-size: 14px;
        }
        .controls button:hover {
            background: #0052a3;
        }
        .controls button:disabled {
            background: #666;
            cursor: not-allowed;
        }
    </style>
</head>
<body>
    <div class="header">
        <h1>🌙 Midnight Development Platform - Web Terminal</h1>
        <div class="status">
            <span class="status-indicator"></span>
            <span id="status-text">Connecting...</span>
        </div>
    </div>
    <div id="terminal-container">
        <div id="terminal"></div>
    </div>
    <div class="controls">
        <button onclick="clearTerminal()">Clear</button>
        <button onclick="window.open('/opencode', '_blank')">Open OpenCode AI</button>
        <button onclick="runCommand('midnight help')">Midnight Help</button>
        <button onclick="runCommand('ls -la')">List Files</button>
        <button onclick="searchTerminal()">Search (Ctrl+F)</button>
        <button onclick="toggleFullscreen()">Fullscreen</button>
    </div>
    
    <script src="https://cdn.jsdelivr.net/npm/@xterm/xterm@5.5.0/lib/xterm.js"></script>
    <script src="https://cdn.jsdelivr.net/npm/@xterm/addon-fit@0.10.0/lib/addon-fit.js"></script>
    <script src="https://cdn.jsdelivr.net/npm/@xterm/addon-web-links@0.11.0/lib/addon-web-links.js"></script>
    <script src="https://cdn.jsdelivr.net/npm/@xterm/addon-search@0.15.0/lib/addon-search.js"></script>
    <script>
        const term = new Terminal({
            cursorBlink: true,
            fontSize: 14,
            fontFamily: 'Menlo, Monaco, "Courier New", monospace',
            allowTransparency: true,
            scrollback: 10000,
            tabStopWidth: 4,
            bellStyle: 'sound',
            theme: {
                background: '#1e1e1e',
                foreground: '#d4d4d4',
                cursor: '#ffffff',
                selection: '#264f78',
                black: '#1e1e1e',
                red: '#f44747',
                green: '#608b4e',
                yellow: '#dcdcaa',
                blue: '#569cd6',
                magenta: '#c678dd',
                cyan: '#56b6c2',
                white: '#d4d4d4',
                brightBlack: '#808080',
                brightRed: '#f44747',
                brightGreen: '#608b4e',
                brightYellow: '#dcdcaa',
                brightBlue: '#569cd6',
                brightMagenta: '#c678dd',
                brightCyan: '#56b6c2',
                brightWhite: '#ffffff'
            }
        });
        
        const fitAddon = new AddonFit.FitAddon();
        const webLinksAddon = new AddonWebLinks.WebLinksAddon();
        const searchAddon = new AddonSearch.SearchAddon();
        
        term.loadAddon(fitAddon);
        term.loadAddon(webLinksAddon);
        term.loadAddon(searchAddon);
        
        term.open(document.getElementById('terminal'));
        fitAddon.fit();
        
        // WebSocket connection - fix for proper WebSocket URL
        const protocol = window.location.protocol === 'https:' ? 'wss:' : 'ws:';
        const wsUrl = protocol + '//' + window.location.host + '/terminal';
        console.log('Connecting to WebSocket:', wsUrl);
        const ws = new WebSocket(wsUrl);
        
        ws.onopen = () => {
            console.log('WebSocket connected');
            document.getElementById('status-text').textContent = 'Connected';
            term.writeln('\\x1b[1;32mConnecting to Midnight Development Platform...\\x1b[0m');
            term.writeln('');
            term.focus();
        };
        
        ws.onmessage = (event) => {
            term.write(event.data);
        };
        
        ws.onclose = () => {
            document.getElementById('status-text').textContent = 'Disconnected';
            term.write('\\r\\n\\r\\n[Connection closed]\\r\\n');
        };
        
        ws.onerror = (error) => {
            console.error('WebSocket error:', error);
            document.getElementById('status-text').textContent = 'Error';
        };
        
        term.onData((data) => {
            ws.send(data);
        });
        
        // Resize handling
        window.addEventListener('resize', () => {
            fitAddon.fit();
        });
        
        // Control functions
        function clearTerminal() {
            term.clear();
        }
        

        
        function runCommand(cmd) {
            ws.send(cmd + '\\r');
        }
        
        function toggleFullscreen() {
            if (!document.fullscreenElement) {
                document.documentElement.requestFullscreen();
            } else {
                document.exitFullscreen();
            }
        }
        
        function searchTerminal() {
            const searchTerm = prompt('Search for:');
            if (searchTerm) {
                searchAddon.findNext(searchTerm, {
                    regex: false,
                    wholeWord: false,
                    caseSensitive: false
                });
            }
        }
        
        // Keyboard shortcuts
        document.addEventListener('keydown', (e) => {
            // Ctrl+F for search
            if (e.ctrlKey && e.key === 'f') {
                e.preventDefault();
                searchTerminal();
            }
            // Ctrl+L to clear
            if (e.ctrlKey && e.key === 'l') {
                e.preventDefault();
                clearTerminal();
            }
        });
    </script>
</body>
</html>
    `);
});

// OpenCode AI page
app.get('/opencode', (req, res) => {
    res.send(`
<!DOCTYPE html>
<html>
<head>
    <title>OpenCode AI Assistant</title>
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/@xterm/xterm@5.5.0/css/xterm.css" />
    <style>
        body {
            margin: 0;
            padding: 0;
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            background: #0d1117;
            color: #fff;
            height: 100vh;
            display: flex;
            flex-direction: column;
        }
        .header {
            background: #161b22;
            padding: 10px 20px;
            border-bottom: 1px solid #30363d;
            display: flex;
            align-items: center;
            justify-content: space-between;
        }
        .header h1 {
            margin: 0;
            font-size: 18px;
            font-weight: 500;
            color: #58a6ff;
        }
        #terminal-container {
            flex: 1;
            padding: 10px;
            overflow: hidden;
        }
        #terminal {
            height: 100%;
            width: 100%;
        }
        .controls {
            background: #161b22;
            padding: 10px 20px;
            border-top: 1px solid #30363d;
            display: flex;
            gap: 10px;
        }
        .controls button {
            padding: 6px 12px;
            background: #238636;
            color: white;
            border: none;
            border-radius: 6px;
            cursor: pointer;
            font-size: 14px;
        }
        .controls button:hover {
            background: #2ea043;
        }
        .info {
            background: #0d1117;
            border: 1px solid #30363d;
            border-radius: 6px;
            padding: 8px 12px;
            margin-left: auto;
            font-size: 13px;
            color: #8b949e;
        }
    </style>
</head>
<body>
    <div class="header">
        <h1>🤖 OpenCode AI Assistant</h1>
        <span class="info">AI-powered coding help for Midnight Network</span>
    </div>
    <div id="terminal-container">
        <div id="terminal"></div>
    </div>
    <div class="controls">
        <button onclick="clearTerminal()">Clear</button>
        <button onclick="restartOpenCode()">Restart</button>
        <button onclick="window.open('/', '_blank')">Open Terminal</button>
        <button onclick="toggleFullscreen()">Fullscreen</button>
    </div>
    
    <script src="https://cdn.jsdelivr.net/npm/@xterm/xterm@5.5.0/lib/xterm.js"></script>
    <script src="https://cdn.jsdelivr.net/npm/@xterm/addon-fit@0.10.0/lib/addon-fit.js"></script>
    <script src="https://cdn.jsdelivr.net/npm/@xterm/addon-web-links@0.11.0/lib/addon-web-links.js"></script>
    <script>
        const term = new Terminal({
            cursorBlink: true,
            fontSize: 14,
            fontFamily: 'Menlo, Monaco, "Courier New", monospace',
            theme: {
                background: '#0d1117',
                foreground: '#c9d1d9',
                cursor: '#58a6ff',
                selection: '#3392ff44',
                black: '#484f58',
                red: '#ff7b72',
                green: '#3fb950',
                yellow: '#d29922',
                blue: '#58a6ff',
                magenta: '#bc8cff',
                cyan: '#39c5cf',
                white: '#b1bac4',
                brightBlack: '#6e7681',
                brightRed: '#ffa198',
                brightGreen: '#56d364',
                brightYellow: '#e3b341',
                brightBlue: '#79c0ff',
                brightMagenta: '#d2a8ff',
                brightCyan: '#56d4dd',
                brightWhite: '#f0f6fc'
            }
        });
        
        const fitAddon = new AddonFit.FitAddon();
        const webLinksAddon = new AddonWebLinks.WebLinksAddon();
        
        term.loadAddon(fitAddon);
        term.loadAddon(webLinksAddon);
        
        term.open(document.getElementById('terminal'));
        fitAddon.fit();
        
        // Connect to OpenCode WebSocket
        const protocol = window.location.protocol === 'https:' ? 'wss:' : 'ws:';
        const ws = new WebSocket(protocol + '//' + window.location.host + '/opencode-ws');
        
        ws.onopen = () => {
            term.writeln('\\x1b[1;32mStarting OpenCode AI Assistant...\\x1b[0m');
            term.writeln('');
            term.focus();
        };
        
        ws.onmessage = (event) => {
            term.write(event.data);
        };
        
        ws.onclose = () => {
            term.write('\\r\\n\\r\\n[OpenCode session ended]\\r\\n');
        };
        
        term.onData((data) => {
            ws.send(data);
        });
        
        window.addEventListener('resize', () => {
            fitAddon.fit();
        });
        
        function clearTerminal() {
            term.clear();
        }
        
        function restartOpenCode() {
            ws.send('\\x03'); // Ctrl+C
            setTimeout(() => {
                ws.send('\\x03'); // Another Ctrl+C
                setTimeout(() => {
                    ws.send('opencode-ai\\r');
                }, 500);
            }, 500);
        }
        
        function toggleFullscreen() {
            if (!document.fullscreenElement) {
                document.documentElement.requestFullscreen();
            } else {
                document.exitFullscreen();
            }
        }
    </script>
</body>
</html>
    `);
});

// WebSocket for regular terminal
app.ws('/terminal', (ws, req) => {
    // Spawn a bash shell with profile and welcome message
    const shell = process.env.SHELL || '/bin/bash';
    
    // Create init script that sources profile and shows welcome
    const initScript = `
#!/bin/bash
source /etc/profile.d/midnight.sh 2>/dev/null || true
clear
echo '╔══════════════════════════════════════════════════════════════╗'
echo '║         Welcome to Midnight Development Platform            ║'
echo '║                        MVP v0.1.0                           ║'
echo '╚══════════════════════════════════════════════════════════════╝'
echo ''
echo '🚀 Quick Start Commands:'
echo '  • midnight new <project>  - Create new DApp project'
echo '  • opencode-ai            - Launch AI code assistant'
echo '  • help                   - Show all available commands'
echo ''
echo '📁 Current directory: /workspace'
echo '📚 Try: cd templates/basic-token && make compile'
echo ''
exec bash --login
`;
    
    require('fs').writeFileSync('/tmp/terminal-init.sh', initScript);
    require('fs').chmodSync('/tmp/terminal-init.sh', '755');
    
    const ptyProcess = pty.spawn('/tmp/terminal-init.sh', [], {
        name: 'xterm-color',
        cols: 80,
        rows: 30,
        cwd: process.env.WORKSPACE || '/workspace',
        env: Object.assign({}, process.env, {
            COLORTERM: 'truecolor',
            TERM: 'xterm-256color',
            PS1: '\\[\\033[01;32m\\]midnight\\[\\033[00m\\]:\\[\\033[01;34m\\]\\w\\[\\033[00m\\]$ '
        })
    });

    // Handle data from pty to websocket
    ptyProcess.onData((data) => {
        try {
            ws.send(data);
        } catch (ex) {
            // Client probably disconnected
        }
    });

    // Handle data from websocket to pty
    ws.on('message', (msg) => {
        ptyProcess.write(msg);
    });

    // Handle resize
    ws.on('resize', (msg) => {
        const { cols, rows } = JSON.parse(msg);
        ptyProcess.resize(cols, rows);
    });

    // Cleanup on close
    ws.on('close', () => {
        ptyProcess.kill();
    });
});

// WebSocket for OpenCode AI
app.ws('/opencode-ws', (ws, req) => {
    // Spawn opencode-ai directly
    const ptyProcess = pty.spawn('opencode-ai', [], {
        name: 'xterm-color',
        cols: 80,
        rows: 30,
        cwd: process.env.WORKSPACE || '/workspace',
        env: Object.assign({}, process.env, {
            COLORTERM: 'truecolor',
            TERM: 'xterm-256color'
        })
    });

    // Handle data from pty to websocket
    ptyProcess.onData((data) => {
        try {
            ws.send(data);
        } catch (ex) {
            // Client probably disconnected
        }
    });

    // Handle data from websocket to pty
    ws.on('message', (msg) => {
        ptyProcess.write(msg);
    });

    // Handle resize
    ws.on('resize', (msg) => {
        const { cols, rows } = JSON.parse(msg);
        ptyProcess.resize(cols, rows);
    });

    // Cleanup on close
    ws.on('close', () => {
        ptyProcess.kill();
    });
    
    // Handle pty exit
    ptyProcess.onExit(() => {
        ws.close();
    });
});

// Error handling middleware
app.use((err, req, res, next) => {
    console.error('Server error:', err);
    res.status(500).json({ error: 'Internal server error' });
});

// Start server with error handling
server.listen(PORT, '0.0.0.0', () => {
    console.log(`OpenCode Web Terminal running on http://0.0.0.0:${PORT}`);
    console.log(`Access from browser at http://localhost:${PORT}`);
    console.log(`WebSocket endpoints available at ws://localhost:${PORT}/terminal and ws://localhost:${PORT}/opencode-ws`);
}).on('error', (err) => {
    if (err.code === 'EADDRINUSE') {
        console.error(`Port ${PORT} is already in use. Try setting TERMINAL_PORT to a different port.`);
    } else if (err.code === 'EACCES') {
        console.error(`Permission denied for port ${PORT}. Try a port above 1024.`);
    } else {
        console.error('Failed to start server:', err);
    }
    process.exit(1);
});