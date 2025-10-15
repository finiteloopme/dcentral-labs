const express = require('express');
const WebSocket = require('ws');
const pty = require('node-pty');
const path = require('path');

const app = express();
const port = 8080;

// Add CORS headers for all origins (needed for local development)
app.use((req, res, next) => {
    res.header('Access-Control-Allow-Origin', '*');
    res.header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
    res.header('Access-Control-Allow-Headers', 'Origin, X-Requested-With, Content-Type, Accept');
    if (req.method === 'OPTIONS') {
        res.sendStatus(200);
    } else {
        next();
    }
});

// Serve static files
app.use(express.static(__dirname));

// Health check endpoint
app.get('/health', (req, res) => {
    res.json({ status: 'ok', service: 'opencode-terminal' });
});

// Serve the main HTML page
app.get('/', (req, res) => {
    res.sendFile(path.join(__dirname, 'index.html'));
});

const server = app.listen(port, '0.0.0.0', () => {
    console.log(`OpenCode web terminal server running on http://0.0.0.0:${port}`);
    console.log(`Health check: http://0.0.0.0:${port}/health`);
});

// WebSocket server for terminal communication
const wss = new WebSocket.Server({ server });

wss.on('connection', (ws) => {
    console.log('New terminal connection established');
    
    // Create a new pseudo terminal
    const shell = process.env.SHELL || '/bin/bash';
    const ptyProcess = pty.spawn(shell, [], {
        name: 'xterm-color',
        cols: 80,
        rows: 30,
        cwd: process.env.HOME || '/home/user',
        env: process.env
    });

    // Handle data from pty to websocket
    ptyProcess.onData((data) => {
        try {
            ws.send(JSON.stringify({ type: 'output', data }));
        } catch (err) {
            console.error('Error sending data to client:', err);
        }
    });

    // Handle exit
    ptyProcess.onExit(({ exitCode, signal }) => {
        console.log(`Terminal process exited with code ${exitCode} and signal ${signal}`);
        ws.close();
    });

    // Handle data from websocket to pty
    ws.on('message', (message) => {
        try {
            const msg = JSON.parse(message);
            
            switch(msg.type) {
                case 'input':
                    ptyProcess.write(msg.data);
                    break;
                case 'resize':
                    ptyProcess.resize(msg.cols, msg.rows);
                    break;
            }
        } catch (err) {
            console.error('Error processing client message:', err);
        }
    });

    // Clean up on disconnect
    ws.on('close', () => {
        console.log('Terminal connection closed');
        ptyProcess.kill();
    });

    ws.on('error', (err) => {
        console.error('WebSocket error:', err);
        ptyProcess.kill();
    });

    // Send initial prompt
    setTimeout(() => {
        ptyProcess.write('echo "Welcome to OpenCode Terminal! Run \\"opencode\\" to start the TUI."\n');
        ptyProcess.write('clear\n');
    }, 100);
});